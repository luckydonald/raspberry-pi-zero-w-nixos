# Copy of nixpkgs' nixos/lib/make-ext4-fs.nix with one change: `-E no_copy_xattrs` added to the
# mkfs.ext4 invocation.
#
# Why this exists: on a build host with SELinux enabled (e.g. Fedora), every file under
# /nix/store carries a `security.selinux` xattr. mke2fs's `-d ./rootImage` populate step tries
# to copy that xattr into the ext4 image, but under the sandboxed/fakeroot build environment,
# `listxattr` reports the attribute name while `getxattr` can't actually retrieve its value —
# `mkfs.ext4: No data available while populating file system`, failing the whole image build.
# The Pi's rootfs has no use for a build-host SELinux label anyway, so skipping xattr copying
# entirely (rather than fighting the host's SELinux/sandbox interaction) is the correct fix, not
# just a workaround. Set via `sdImage.rootFilesystemCreator` in configuration.nix, which exists
# precisely for swapping in an alternate filesystem-creator implementation like this one.
{
  pkgs,
  lib,
  storePaths,
  compressImage ? false,
  zstd,
  populateImageCommands ? "",
  volumeLabel,
  uuid ? "44444444-4444-4444-8888-888888888888",
  e2fsprogs,
  libfaketime,
  perl,
  fakeroot,
}:

let
  sdClosureInfo = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
in
pkgs.stdenv.mkDerivation {
  name = "ext4-fs.img${lib.optionalString compressImage ".zst"}";

  nativeBuildInputs = [
    e2fsprogs.bin
    libfaketime
    perl
    fakeroot
  ]
  ++ lib.optional compressImage zstd;

  buildCommand = ''
    ${if compressImage then "img=temp.img" else "img=$out"}
    (
    mkdir -p ./files
    ${populateImageCommands}
    )

    echo "Preparing store paths for image..."

    # Create nix/store before copying path
    mkdir -p ./rootImage/nix/store

    xargs -I % cp -a --reflink=auto % -t ./rootImage/nix/store/ < ${sdClosureInfo}/store-paths
    (
      GLOBIGNORE=".:.."
      shopt -u dotglob

      for f in ./files/*; do
          cp -a --reflink=auto -t ./rootImage/ "$f"
      done
    )

    # Also include a manifest of the closures in a format suitable for nix-store --load-db
    cp ${sdClosureInfo}/registration ./rootImage/nix-path-registration

    # Make a crude approximation of the size of the target image.
    # If the script starts failing, increase the fudge factors here.
    numInodes=$(find ./rootImage | wc -l)
    numDataBlocks=$(du -s -c -B 4096 --apparent-size ./rootImage | tail -1 | awk '{ print int($1 * 1.20) }')
    bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
    echo "Creating an EXT4 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

    mebibyte=$(( 1024 * 1024 ))
    # Round up to the nearest mebibyte.
    # This ensures whole 512 bytes sector sizes in the disk image
    # and helps towards aligning partitions optimally.
    if (( bytes % mebibyte )); then
      bytes=$(( ( bytes / mebibyte + 1) * mebibyte ))
    fi

    truncate -s $bytes $img

    faketime -f "1970-01-01 00:00:01" fakeroot mkfs.ext4 -E no_copy_xattrs -L ${volumeLabel} -U ${uuid} -d ./rootImage $img

    export EXT2FS_NO_MTAB_OK=yes
    # I have ended up with corrupted images sometimes, I suspect that happens when the build machine's disk gets full during the build.
    if ! fsck.ext4 -n -f $img; then
      echo "--- Fsck failed for EXT4 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks) ---"
      cat errorlog
      return 1
    fi

    # We may want to shrink the file system and resize the image to
    # get rid of the unnecessary slack here--but see
    # https://github.com/NixOS/nixpkgs/issues/125121 for caveats.

    # shrink to fit
    resize2fs -M $img

    # Add 16 MebiByte to the current_size
    new_size=$(dumpe2fs -h $img | awk -F: \
      '/Block count/{count=$2} /Block size/{size=$2} END{print (count*size+16*2**20)/size}')

    resize2fs $img $new_size

    if [ ${toString compressImage} ]; then
      echo "Compressing image"
      zstd -T$NIX_BUILD_CORES -v --no-progress ./$img -o $out
    fi
  '';
}
