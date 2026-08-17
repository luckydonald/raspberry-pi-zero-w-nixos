# NixOS on a Raspberry Pi Zero W (v1, armv6l)

A flake-based NixOS setup for the *original* Raspberry Pi Zero W — BCM2835, single-core
ARM1176JZF-S, armv6l, 512MB RAM, WiFi/Bluetooth-only (no Ethernet, no HDMI). It's built to be
run headless from first boot.

## Why this is harder than it sounds

nixpkgs' Hydra binary cache does **not** build for `armv6l`. Almost the entire system closure
has to be compiled from source, and building natively on the Pi itself is impractical (too slow,
too little RAM). So everything here is built via true cross-compilation (`nixpkgs.crossSystem`)
from a regular x86_64 machine, producing a flashable SD card image. Expect long first builds.

There's also no `nixos-hardware` profile for this board (only Pi 2/3/4/5 are covered), and the
old `boot.loader.raspberryPi` bootloader module this board historically used is now deprecated
— see [`devices/rpi-zero-w/configuration.nix`](devices/rpi-zero-w/configuration.nix) for the
current `generic-extlinux-compatible` + U-Boot replacement.

## Layout

- [`devices/rpi-zero-w/`](devices/rpi-zero-w/) — the base image: boot loader, kernel, firmware,
  WiFi, SSH, and GPIO/I2C/SPI enablement. Nothing app-specific. Meant to stand alone as a base
  other projects can build on, not just the one below.
- [`example/radio/`](example/radio/) — an always-on internet radio player built on top of the
  base image, using the Pi Zero W's onboard Bluetooth to talk to a Bluetooth speaker. Kept
  self-contained on purpose (it's a candidate for splitting into its own repo later); see its
  own [README](example/radio/README.md) for details.

## Build & flash the base image

```sh
nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
zstd -dcf result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=64k status=progress
```

Double-check `/dev/sdX` is actually the SD card before writing.

## First boot: WiFi & SSH

This build contains **no personal data at all** — no WiFi password, no SSH key, nothing tied to
you. That's deliberate: it's the same image whether you're flashing it for yourself or it's a
published [Release](#releases) someone else downloaded. Nix bakes anything it reads at build
time straight into the image, so instead these four values live as plain text files on the SD
card's `FIRMWARE` partition — the small FAT32 partition, separate from the main Linux one — read
by the running system at *boot*, not by Nix at *build* time. That partition mounts as an
ordinary drive on Windows/Mac/Linux, so after flashing:

1. Re-insert the SD card into your computer (or just don't eject it yet) and open the
   `FIRMWARE` partition.
2. Edit **`wpa_supplicant.conf`** with your real WiFi SSID and password.
3. Paste your SSH public key(s) (e.g. the contents of `~/.ssh/id_ed25519.pub`) into
   **`authorized_keys`**, one per line.
4. Eject, put the card in the Pi, and power it on.

This is the same convention Raspberry Pi OS itself uses for headless setup (dropping
`wpa_supplicant.conf`/`ssh` onto the boot partition pre-boot), so it may already be familiar.

Find the Pi's address once it's joined WiFi (router DHCP lease list, or `avahi`/mDNS if you have
that set up), then:

```sh
ssh root@rpi-zero-w
```

**Re-flashing note:** writing a newer image resets this partition back to placeholder defaults —
back up your edited `wpa_supplicant.conf`/`authorized_keys` (and, for the radio image,
`radio-station-url`/`bluetooth-speaker-mac`) before reflashing an already-configured device.

For the radio build instead, see [`example/radio/README.md`](example/radio/README.md).

## Releases

Tagged versions (`vX.Y.Z`) get built and published automatically by
[`.github/workflows/release.yml`](.github/workflows/release.yml) — grab a prebuilt
`rpi-zero-w-vX.Y.Z.img.zst` or `rpi-zero-w-radio-vX.Y.Z.img.zst` from the
[Releases page](../../releases) instead of building locally if you just want to flash and go.

## Binary cache

armv6l has no upstream Hydra cache, so every build here compiles a large chunk of nixpkgs from
source — the first build especially can take hours. [`.github/workflows/nix-cache-warm.yml`](.github/workflows/nix-cache-warm.yml)
cross-compiles both `nixosConfigurations` weekly (and on manual trigger) and pushes every store
path it builds to a personal [Cachix](https://cachix.org) cache, `luckydonald-rpi-zero-w`, as
soon as each one finishes — so a run that hits GitHub's job timeout still leaves useful progress
behind for the next one to build on.

### Use the provided cache

Add it as a substituter once, then `nix build` pulls from it instead of rebuilding from source
wherever it can:

```sh
nix run nixpkgs#cachix -- use luckydonald-rpi-zero-w
```

If that errors with `doesn't have permissions to configure binary caches`, your user isn't a Nix
`trusted-user` yet (needed to add substituters) — fix once, then retry:

```sh
echo "trusted-users = root user" | sudo tee -a /etc/nix/nix.conf && sudo pkill nix-daemon
```

(`user` above is whatever your actual OS username is — the Nix daemon restarts itself under
systemd, picking up the new setting.)

### Set up your own cache instead (or in addition)

If you're building your own fork/derivative of this repo and want your own warm cache:

1. Sign up and create a cache at [app.cachix.org](https://app.cachix.org) (see the
   [Cachix docs](https://docs.cachix.org) for the general concepts). Free tier is generous for a
   personal cache like this one.
2. Install the CLI and authenticate:
   ```sh
   nix profile install nixpkgs#cachix
   cachix authtoken <your-token-from-the-cachix-dashboard>
   ```
3. **Point your cache at this one so you benefit from the already-built closure instead of
   starting from zero:** in the Cachix dashboard, open your cache → *Settings* → **Upstream
   caches**, and add `luckydonald-rpi-zero-w`. Cachix then falls through to it automatically for
   any store path your own cache doesn't have yet, before your own CI has to build it.
4. Add it as a local substituter the same way as above, with your own cache name:
   ```sh
   cachix use <your-cache-name>
   ```
5. To run the weekly warming workflow against your own cache: add a `CACHIX_AUTH_TOKEN` secret
   (a write token from your Cachix dashboard) under your fork's repo Settings → Secrets and
   variables → Actions, and change the `name:` field in
   [`.github/workflows/nix-cache-warm.yml`](.github/workflows/nix-cache-warm.yml) from
   `luckydonald-rpi-zero-w` to your own cache name.

Repo maintainers of *this* repo: same step 5, but no `name:` change needed — the workflow already
targets `luckydonald-rpi-zero-w`.

## Sources / credits

This leans directly on prior art for this specific board:

- [NixOS Wiki — NixOS on ARM/Raspberry Pi](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi) —
  boot-process background, device tree overlay guidance, the Bluetooth-over-UART recipe used in
  the radio example.
- [cyber-murmel/nixos-rpi-zero-w](https://github.com/cyber-murmel/nixos-rpi-zero-w) — an earlier
  working NixOS config for this exact board (predates the `boot.loader.raspberryPi`
  deprecation; the boot approach here is adapted from it).
- [NixOS Discourse — "NixOS on raspberry pi zero w"](https://discourse.nixos.org/t/nixos-on-raspberry-pi-zero-w/38018) —
  armv6l cross-compile pitfalls and a documented, still-open rough edge around I2C on this
  board.
- [nixpkgs PR #241534](https://github.com/NixOS/nixpkgs/pull/241534) — deprecation of
  `boot.loader.raspberryPi` and the rationale for the `generic-extlinux-compatible` + U-Boot
  replacement used here.
