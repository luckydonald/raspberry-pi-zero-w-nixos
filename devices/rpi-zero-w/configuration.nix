# Base NixOS config for an original Raspberry Pi Zero W (v1, BCM2835, armv6l).
#
# Deliberately app-agnostic: boot loader, kernel, firmware, WiFi, SSH, and GPIO/I2C/SPI
# enablement only. See ../../example/radio/ for a project built on top of this.
{ config, pkgs, lib, modulesPath, ... }:

{
  # Target platform is set by flake.nix via `nixpkgs.crossSystem` (true cross-compilation from
  # an x86_64-linux build host), not here — this file stays agnostic about how it gets built.

  # Not using nixpkgs' sd-image-aarch64.nix (wrong architecture/firmware) — just its generic
  # base, which defines the `sdImage.*` options and the `system.build.sdImage` derivation we
  # populate by hand below for this board.
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  # --- Boot ---------------------------------------------------------------
  #
  # `boot.loader.raspberryPi` (firmware boots straight into a kernel image, no U-Boot) is
  # deprecated (nixpkgs PR #241534). Use the same generic-extlinux-compatible + U-Boot
  # mechanism nixpkgs' own sd-image-aarch64.nix uses for the 64-bit Pis, just retargeted at
  # this board's armv6l U-Boot build (`ubootRaspberryPiZero`, rpi_0_w_defconfig).
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Deliberately NOT pkgs.linuxPackages_rpi0 (the Raspberry Pi Foundation's downstream
  # kernel): as of nixpkgs' current "linux-rpi" package, it's a single build shared across all
  # Pi boards and it fails to cross-compile for armv6l — it bundles RP1-southbridge driver
  # modules (Pi 5-only hardware) that reference 64-bit-division helpers
  # (`__aeabi_uldivmod`/`__aeabi_ldivmod`) unavailable on armv6l, so `modpost` errors out. The
  # plain mainline kernel (this board's default) has long-standing native upstream support for
  # BCM2835/Pi1/Zero and carries none of that newer-board baggage — per the NixOS wiki, "The
  # ARMv6 image boots out-of-the-box" on the mainline kernel for this board.

  # Keep the initrd small and fast to build/cross-compile: this board only ever boots off the
  # SD card, so it doesn't need the full default module set.
  #
  # mkForce on availableKernelModules: sd-image.nix (imported above) bakes in its own
  # installer-oriented module list (autofs, efivarfs, tpm-crb, ...) meant for broad x86/UEFI
  # hardware compatibility — none of which this board has or ever will. List-typed options merge
  # (concatenate) across modules by default rather than override, and several of those modules
  # (tpm-crb in particular) aren't even built for this board's minimal ARM kernel config, so
  # without mkForce the initrd build fails trying to modprobe a module that doesn't exist.
  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = lib.mkForce [ "ext4" "mmc_block" ];

  sdImage.compressImage = true;

  # See make-ext4-fs-no-xattrs.nix: needed to build on an SELinux-enabled build host (e.g.
  # Fedora), where the stock filesystem creator fails trying to copy `security.selinux` xattrs
  # into the image.
  sdImage.rootFilesystemCreator = ./make-ext4-fs-no-xattrs.nix;

  # Every value here that's personal to a specific deployment (WiFi credentials, SSH keys, and
  # — for the radio image, see example/radio/ — the station URL and Bluetooth speaker MAC) is
  # deliberately NOT baked into this build. Nix bakes anything it reads at build time literally
  # into the built system's /nix/store, which ships inside the image — safe for a device only
  # you ever flash, but not for an image published as a GitHub Release. Instead, those values
  # live in plain text files on this FAT firmware partition, read by the running system at
  # *boot*, not by Nix at *build* time. The partition stays writable/mountable from any OS
  # after flashing — the same trick Raspberry Pi OS itself uses for its well-known headless
  # setup (dropping wpa_supplicant.conf/ssh/userconf.txt onto the boot partition pre-boot).
  sdImage.populateFirmwareCommands =
    let
      firmware = pkgs.raspberrypifw;
      uboot = pkgs.ubootRaspberryPiZero;
    in
    ''
      cp ${firmware}/share/raspberrypi/boot/bootcode.bin firmware/
      cp ${firmware}/share/raspberrypi/boot/fixup*.dat firmware/
      cp ${firmware}/share/raspberrypi/boot/start*.elf firmware/
      cp ${uboot}/u-boot.bin firmware/kernel.img

      cat > firmware/config.txt << 'EOF'
      kernel=kernel.img
      enable_uart=1
      EOF

      cat > firmware/wpa_supplicant.conf << 'EOF'
      # Edit this file with your real WiFi network before first boot. It lives on this FAT
      # partition, so you can edit it from any computer (Windows/Mac/Linux) with the SD card
      # inserted, before it ever goes into the Pi. Re-flashing to a newer image resets this
      # file back to these placeholders — back it up first if you're updating an existing device.
      #
      # country: your two-letter ISO 3166-1 country code (regulatory domain for WiFi channels).
      country=US
      ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
      update_config=1

      network={
          ssid="YOUR_WIFI_SSID"
          psk="YOUR_WIFI_PASSWORD"
      }
      EOF

      cat > firmware/authorized_keys << 'EOF'
      # Paste your SSH public key(s) here, one per line (e.g. the contents of
      # ~/.ssh/id_ed25519.pub), then boot or reboot the Pi. No rebuild needed: sshd reads this
      # file directly from this partition on every login attempt.
      EOF
    '';

  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';

  # --- Firmware / WiFi ------------------------------------------------------
  #
  # Known-needed combo for WiFi to actually come up on this board: skip the general
  # redistributable-firmware blob and pull in just the RPi wireless firmware.
  #
  # mkForce: the generic sd-image.nix base we import pulls in profiles/all-hardware.nix (it's
  # meant to double as an x86 installer-CD image, supporting arbitrary hardware). Beyond forcing
  # this to true, it also force-adds a huge boot.initrd.availableKernelModules list of x86
  # SATA/RAID/etc. modules — irrelevant here, and actually fatal: the mainline kernel's minimal
  # ARM config doesn't build most of them, so the initrd "modules-shrunk" build step fails
  # trying to modprobe a module (e.g. `3w-9xxx`, a 3ware RAID controller) that doesn't exist for
  # this kernel. Disabling the whole profile is correct, not just working around the symptom.
  hardware.enableAllHardware = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  # --- GPIO / I2C / SPI ------------------------------------------------------
  #
  # Not used yet — generic i2c/deviceTree support is enabled up front so a future hardware
  # project doesn't need a rebuild from scratch, but the actual i2c1/spi0 dtoverlay is NOT
  # wired up here (yet): a plain `dtoverlay=`-style fragment targeting `&i2c1`/`&spi0` by label
  # fails to build against this board's dtb with `FDT_ERR_NOTFOUND` — a documented, known rough
  # edge (NixOS wiki's device-trees section, and the NixOS Discourse thread linked in the
  # README) whose fix is switching to `dtmerge` instead of plain overlay application, not
  # something to reach for casually. Follow-up work, not a blocker for Part 1 (boot + SSH).
  hardware.i2c.enable = true;
  hardware.deviceTree.enable = true;

  # --- Networking -------------------------------------------------------
  #
  # NOT using NixOS's `networking.wireless.networks.<ssid>` here — that option needs the SSID as
  # a Nix attribute name, which means it has to be known at *build* time no matter what, so it
  # can't be deferred to the boot partition the way the PSK can. Running wpa_supplicant
  # ourselves, pointed at a plain conf file on /boot/firmware, keeps both SSID and PSK entirely
  # out of the build.
  networking.hostName = "rpi-zero-w";
  systemd.services.wpa-supplicant-boot-partition = {
    description = "wpa_supplicant using /boot/firmware/wpa_supplicant.conf";
    wantedBy = [ "multi-user.target" ];
    after = [ "sys-subsystem-net-devices-wlan0.device" ];
    serviceConfig = {
      ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i wlan0 -c /boot/firmware/wpa_supplicant.conf";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # --- SSH ----------------------------------------------------------------
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  # sshd reads this straight off the boot partition on every login attempt — a plain runtime
  # file lookup, not something Nix reads at build time, so no key ever ends up in the store.
  services.openssh.authorizedKeysFiles = [ "/boot/firmware/authorized_keys" ];

  # Keep the base image's package set minimal — anything not baked in has to build/fetch
  # on-device later, which is impractical on this board (512MB RAM, single core, no binary
  # cache). Add packages here and rebuild/reflash instead of installing on-device.
  environment.systemPackages = [ pkgs.vim ];

  # Skips nixos-rebuild/nixos-install/nixos-generate-config on-device — fine, since rebuilding
  # is always done by cross-compiling on the build host and reflashing, never on the Pi itself.
  # Also sidesteps a real build failure: nixos-generate-config pulls in pkgs.bcachefs-tools for
  # filesystem detection, and bcachefs-tools (Rust) fails to cross-compile for armv6l (linker
  # error), which otherwise blocks the whole image build over a tool this device never uses.
  system.disableInstallerTools = true;

  system.stateVersion = "24.11";
}
