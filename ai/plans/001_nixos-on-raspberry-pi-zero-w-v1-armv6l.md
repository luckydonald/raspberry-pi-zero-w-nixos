# NixOS on Raspberry Pi Zero W (v1, armv6l)

## Context

This repo is currently just the `base` scaffold (AGENTS.md, ai/ tooling, pre-commit config) — no NixOS
configuration exists yet. The goal is a from-scratch, flake-based NixOS setup that boots on an original
Raspberry Pi Zero W (BCM2835, single-core ARM1176JZF-S, armv6l, 512MB RAM, WiFi-only, no Ethernet/HDMI —
headless from day one).

The critical constraint shaping every decision below: **nixpkgs' Hydra binary cache does not build
`armv6l`.** Nearly the whole system closure has to be compiled from source. Native builds on the Pi
itself are impractical (too slow, too little RAM), so per the user's choice this will be built via true
cross-compilation from their main machine, producing a flashable SD card image.

Research confirms the concrete pieces needed (verified against the NixOS wiki, the nixpkgs source tree,
and a working reference repo, [cyber-murmel/nixos-rpi-zero-w](https://github.com/cyber-murmel/nixos-rpi-zero-w) —
built specifically for this exact device, though 4 years old, which matters for the boot loader point below):

- **Boot loader:** the reference repo (and the older wiki guidance) uses `boot.loader.raspberryPi`
  (`version = 0`), which boots the RPi firmware straight into a kernel image with no U-Boot involved.
  **That module is now deprecated** (nixpkgs PR #241534). The current correct approach — used by
  nixpkgs' own `sd-image-aarch64.nix` module for the 64-bit Pis — is `boot.loader.grub.enable = false;`
  + `boot.loader.generic-extlinux-compatible.enable = true;`, with the RPi firmware partition populated
  by hand (`sdImage.populateFirmwareCommands`) to load **U-Boot** as `kernel.img`, which then reads the
  `extlinux.conf` NixOS generates. U-Boot has a real target for this exact board:
  `pkgs.ubootRaspberryPiZero` (`rpi_0_w_defconfig`, armv6l) — confirmed present in current nixpkgs
  (`pkgs/misc/uboot/default.nix`). This is more manual wiring than the old repo's approach but is the
  non-deprecated path, and reuses the same mechanism nixpkgs already ships for Pi3/4/5, just retargeted
  at armv6l firmware (no `arm_64bit=1` line in `config.txt`, and `ubootRaspberryPiZero` instead of the
  aarch64 variant).
- Kernel package: `pkgs.linuxPackages_rpi0` (verify this attribute still exists in the pinned nixpkgs
  revision at implementation time — kernel package naming has shifted before).
- `hardware.enableRedistributableFirmware = false` with `pkgs.raspberrypiWirelessFirmware` added
  explicitly is a known-needed combo for WiFi to work at all on this board.
- No `nixos-hardware` profile exists for the original Pi Zero (only Pi 2/3/4/5 are covered), so this
  config is hand-built rather than importing a hardware profile.
- Known armv6l cross-compile trouble spots: LLVM/compiler-rt build failures (mitigated by pinning
  `llvmPackages_14` when something pulls in Clang) and a cmake atomic-linking issue (`-latomic` via
  `env.NIX_CFLAGS_COMPILE`). Kept relevant only if something in the closure needs them — the plan below
  keeps `environment.systemPackages` minimal specifically to reduce the chance of hitting these.
- **No analog audio out:** the original Pi Zero/Zero W board has no 3.5mm jack (unlike later Pis) — only
  PWM audio pads, which are unreliable/lo-fi. The internet radio project (below) needs a USB audio
  adapter for real speaker output.

## Decisions locked in with the user

- **Build strategy:** true cross-compilation (`nixpkgs.crossSystem`), not QEMU/binfmt emulation.
- **Scope:** headless first deployment; GPIO/I2C/SPI interfaces enabled up front (via device tree
  overlays in `config.txt`) even though nothing uses them yet, so future projects don't need a rebuild
  from scratch.
- **Config style:** flake-based (user's first time with flakes, so the plan keeps the flake itself small
  and legible).
- **Secrets:** not sops-nix/agenix — a plain **gitignored `.nix` file** imported by the flake, holding the
  WiFi PSK and SSH authorized keys, with a tracked `.example` template. (A literal `.env` file can't be
  natively imported by Nix eval without extra parsing glue; a gitignored `.nix` file gets the same
  "nothing sensitive committed" property while staying a one-line `import`.)

## File layout

```
flake.nix                              # inputs (nixpkgs), nixosConfigurations.rpi-zero-w
hosts/rpi-zero-w/
  configuration.nix                    # boot loader, kernel, firmware, networking, ssh, users
  secrets.nix.example                  # tracked template: { wifi = { ssid, psk }; sshAuthorizedKeys = [...]; }
  secrets.nix                          # gitignored, real values, imported by configuration.nix
```

Add `hosts/rpi-zero-w/secrets.nix` to `.gitignore` (the repo already has broad `.env`/`*secrets*`-style
ignore conventions near the existing `.env` entries — follow that pattern).

## `flake.nix`

- Single input: `nixpkgs` (pin to `nixos-unstable` or a recent stable release — recommend unstable since
  armv6l fixes land there first and this is already an unsupported-tier build).
- `nixosConfigurations.rpi-zero-w = nixpkgs.lib.nixosSystem { system = "x86_64-linux"; modules = [ ... hosts/rpi-zero-w/configuration.nix ]; }`
  with `nixpkgs.crossSystem.system = "armv6l-linux"` set inside a module, so the build host stays
  `x86_64-linux` (their main machine) while the produced system targets armv6l.
- Expose the SD image as a flake output so building it is one command:
  `nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage`

## `hosts/rpi-zero-w/configuration.nix`

- `boot.loader.raspberryPi.enable = true; boot.loader.raspberryPi.version = 0;` (matches Pi Zero/Pi1
  firmware boot, not U-Boot). `boot.loader.grub.enable = false;`
- `boot.kernelPackages = pkgs.linuxPackages_rpi0;` — verify this attribute still exists in the pinned
  nixpkgs revision when implementing; fall back to whatever the current rpi0-target kernel package is
  named if renamed.
- `boot.initrd.includeDefaultModules = false;` with only the modules actually needed
  (`["ext4" "mmc_block"]`) to keep the initrd build small — a trick from the reference repo that avoids
  pulling in unrelated driver builds on this slow-to-build target.
- `hardware.enableRedistributableFirmware = false;` + `hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];`
- Enable I2C/SPI via Raspberry Pi device tree overlay options (`hardware.deviceTree` /
  `boot.loader.raspberryPi.firmwareConfig` `dtparam=i2c_arm=on,spi=on`, or `hardware.i2c.enable = true`
  depending on what the current module exposes) — enabled now, unused until a hardware project needs it.
  Flag to the user during implementation if `/dev/i2c-*` doesn't appear (a documented unresolved rough
  edge for this board in the NixOS Discourse thread) — treat as a known possible follow-up, not a blocker
  for getting the box booting and SSH-reachable.
- Networking: `networking.wireless.enable = true;` (wpa_supplicant, since NetworkManager is heavier and
  not needed for a single always-on WiFi headless box) configured from `secrets.nix`'s
  `wifi.ssid`/`wifi.psk` via `networking.wireless.networks.<ssid>.psk`.
- `services.openssh.enable = true;` with `users.users.<user>.openssh.authorizedKeys.keys` sourced from
  `secrets.nix`'s `sshAuthorizedKeys` list. Password auth off.
- Keep `environment.systemPackages` minimal at first boot (just what's needed to confirm the box is
  alive) — anything not baked into the image will have to build/fetch on-device later, which is
  impractical on a 512MB single-core board with no cache, so prefer adding packages to the image and
  rebuilding/reflashing over installing on-device.

## Build & flash

1. `nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage` on the dev machine (expect a
   long first build — no binary cache for this architecture).
2. Decompress and write: `zstd -dcf result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=64k status=progress`
   (confirm the correct device before writing).
3. Boot the Pi, wait for it to join WiFi, find its address (router DHCP lease list or `avahi`/mDNS if
   enabled), `ssh` in with the key from `secrets.nix`.

## Verification

- Confirm the image builds successfully end-to-end via the `nix build` command above.
- Boot the physical Pi Zero W from the flashed card and confirm it associates to WiFi and becomes
  SSH-reachable — this is the actual pass/fail signal, there's no way to verify armv6l boot behavior
  without the real hardware.
- If I2C/SPI don't appear as `/dev/i2c-*`/`/dev/spidev*` after boot, note it as a known follow-up rather
  than blocking on it, per the unresolved report in the community thread.
