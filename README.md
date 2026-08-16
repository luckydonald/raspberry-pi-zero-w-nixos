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

## First boot: WiFi & SSH

Before building anything, copy the secrets template and fill in real values — this file is
gitignored and never committed:

```sh
cp devices/rpi-zero-w/secrets.nix.example devices/rpi-zero-w/secrets.nix
$EDITOR devices/rpi-zero-w/secrets.nix   # WiFi SSID/PSK, your SSH public key(s)
```

A plain gitignored `.nix` file (rather than sops-nix/agenix) is a deliberate choice for this
personal/single-device repo — nothing sensitive touches git, and it's still just a one-line
`import` in `configuration.nix`, no extra tooling needed.

## Build & flash the base image

```sh
nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
zstd -dcf result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=64k status=progress
```

Double-check `/dev/sdX` is actually the SD card before writing. Boot the Pi, wait for it to join
WiFi, find its address (router DHCP lease list, or `avahi`/mDNS if you have that set up), and:

```sh
ssh root@rpi-zero-w
```

For the radio build instead, see [`example/radio/README.md`](example/radio/README.md).

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
