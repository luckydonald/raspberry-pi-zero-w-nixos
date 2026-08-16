# Base NixOS config for an original Raspberry Pi Zero W (v1, BCM2835, armv6l).
#
# Deliberately app-agnostic: boot loader, kernel, firmware, WiFi, SSH, and GPIO/I2C/SPI
# enablement only. See ../../example/radio/ for a project built on top of this.
{ config, pkgs, lib, modulesPath, ... }:

let
  secrets = import ./secrets.nix;
in
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
  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = [ "ext4" "mmc_block" ];

  sdImage.compressImage = true;

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
  # meant to double as an installer image), which sets this to true.
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  # --- GPIO / I2C / SPI ------------------------------------------------------
  #
  # Not used yet, enabled up front so a future hardware project doesn't need a rebuild from
  # scratch. If /dev/i2c-* doesn't show up after boot, that's a known unresolved rough edge for
  # this board (see NixOS Discourse thread linked in the README) — not a blocker for Part 1.
  hardware.i2c.enable = true;
  hardware.deviceTree.enable = true;
  hardware.deviceTree.overlays = [
    {
      name = "rpi-zero-w-i2c-spi";
      dtsText = ''
        /dts-v1/;
        /plugin/;
        / {
          compatible = "brcm,bcm2835";
          fragment@0 {
            target = <&i2c1>;
            __overlay__ {
              status = "okay";
            };
          };
          fragment@1 {
            target = <&spi0>;
            __overlay__ {
              status = "okay";
            };
          };
        };
      '';
    }
  ];

  # --- Networking -------------------------------------------------------
  #
  # wpa_supplicant via networking.wireless: lighter than NetworkManager, and this is a single
  # always-on WiFi headless box with nothing to switch between.
  networking.hostName = "rpi-zero-w";
  networking.wireless.enable = true;
  networking.wireless.networks.${secrets.wifi.ssid}.psk = secrets.wifi.psk;

  # --- SSH ----------------------------------------------------------------
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = secrets.sshAuthorizedKeys;

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
