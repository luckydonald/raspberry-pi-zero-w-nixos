# Radio example

A NixOS-native, always-on internet radio player for the [base Raspberry Pi Zero W image](../../devices/rpi-zero-w/)
in this repo: on boot it joins WiFi, reconnects to a paired Bluetooth speaker, and starts
playing a pre-configured stream URL — no manual `mpc play` required.

This directory is intentionally self-contained and only ever *composed on top of* the base
device config (see `flake.nix`'s `rpi-zero-w-radio` output) — it never modifies anything under
`devices/rpi-zero-w/`. That's so it can be split out into its own repo later without moving
anything else.

## How it fits together

- [`module.nix`](module.nix) — the MPD daemon itself, plus a `radio-autoplay` systemd unit that
  clears the queue, adds the configured stream URL, and hits play. This is what makes it a
  radio appliance rather than just an idle MPD server.
- [`bluetooth.nix`](bluetooth.nix) — brings up the Pi Zero W's onboard Bluetooth (BCM43438,
  attached over UART), bridges it to ALSA via BlueALSA, reconnects to the paired speaker on
  every boot, and points MPD's `audio_output` at it. The original Pi Zero/Zero W has no 3.5mm
  audio jack, so Bluetooth (rather than a wired USB DAC) is the audio-out path here.

`module.nix` doesn't know or care how audio gets out — it deliberately doesn't set MPD's
`audio_output`, so a future alternative output module (USB DAC, HDMI, whatever) could be
swapped in for `bluetooth.nix` without touching it.

## Configuration

Like WiFi/SSH on the base image (see the root [README](../../README.md#first-boot-wifi--ssh)),
neither of these is a Nix build-time value — a published image shouldn't be stuck playing one
fixed station or trying to talk to one fixed speaker. Both live as plain text files on the SD
card's `FIRMWARE` partition, editable from any computer, read fresh at every boot:

- **Stream URL** — `radio-station-url` on the `FIRMWARE` partition. Ships with a genuinely
  working default (the same BBC World Service stream used throughout this project's docs), not
  a placeholder — editing it is for picking a *different* station, not required to get sound.
- **Speaker MAC address** — `bluetooth-speaker-mac` on the `FIRMWARE` partition. Ships with a
  comment explaining the format; only known after you've paired your speaker once (see below).

## Build & flash

```sh
nix build .#nixosConfigurations.rpi-zero-w-radio.config.system.build.sdImage
zstd -dcf result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=64k status=progress
```

Confirm the correct device before writing — see the root [README](../../README.md) for the
`FIRMWARE`-partition first-boot flow (WiFi/SSH), which applies here too since this image
includes the base device config, plus the two radio-specific files above.

## Pairing the Bluetooth speaker (one-time, manual)

BlueZ remembers *trusted* devices across reboots and `bluetooth-connect.service` reconnects to
them automatically on every boot — but the very first pairing has to happen once, by hand, over
SSH, since there's no way to know which speaker you want to use ahead of time:

```sh
ssh root@rpi-zero-w
bluetoothctl
  power on
  agent on
  scan on
  # wait for your speaker to show up, then:
  pair AA:BB:CC:DD:EE:FF
  trust AA:BB:CC:DD:EE:FF
  connect AA:BB:CC:DD:EE:FF
  scan off
  exit
```

Write that MAC address into `bluetooth-speaker-mac` on the `FIRMWARE` partition (mount the SD
card on any computer, same as the WiFi/SSH setup) and reboot the Pi. No rebuild needed — from
then on, every boot reconnects automatically.

## Debugging

```sh
systemctl status btattach bluetooth bluealsa bluetooth-connect mpd radio-autoplay
mpc status
bluetoothctl info AA:BB:CC:DD:EE:FF   # confirm it shows "Connected: yes"
```

## Sources / credits

- [NixOS Wiki — NixOS on ARM/Raspberry Pi](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi) —
  the `btattach` Bluetooth-over-UART recipe this reuses almost verbatim (originally documented
  for the Pi 3, same BCM43438 combo chip).
- [zbotic — Raspberry Pi Internet Radio: Build an Always-On Music Player](https://zbotic.in/blogs/raspberry-pi-internet-radio-build-an-always-on-music-player/) —
  the shape of this project (MPD-based, always-on internet radio), reimplemented here
  declaratively via NixOS's `services.mpd` module instead of `apt install`/manual `mpd.conf`
  editing.
- [BlueALSA (arkq/bluez-alsa)](https://github.com/arkq/bluez-alsa) — the lightweight BlueZ ↔
  ALSA bridge used for the Bluetooth audio path; chosen over PipeWire for being the more
  commonly recommended, lower-overhead option on a single-core/512MB board like this one.
