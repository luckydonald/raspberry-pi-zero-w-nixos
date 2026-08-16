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
  PWM audio pads, which are unreliable/lo-fi. This is part of why the Part 2 radio project targets a
  Bluetooth speaker for audio out rather than a wired connection.

## Decisions locked in with the user

- **Build strategy:** true cross-compilation (`nixpkgs.crossSystem`), not QEMU/binfmt emulation.
- **Two equally-in-scope deliverables:**
  1. **Part 1 — reusable OS base image:** NixOS booting on the original Pi Zero W hardware — boot
     loader, kernel, firmware, WiFi, SSH, nothing app-specific. That's
     `devices/rpi-zero-w/configuration.nix`, meant to stand alone as a base other projects (not just the
     radio) can build on. GPIO/I2C/SPI interfaces are enabled up front (via device tree overlays) even
     though nothing needs them yet, so later projects don't require a rebuild from scratch.
  2. **Part 2 — the actual working radio player:** on boot, with no manual intervention, the Pi
     connects to WiFi, pairs/reconnects to a Bluetooth speaker, and starts playing a pre-configured
     stream URL — a real always-on internet radio appliance, not just an MPD daemon standing by for a
     `mpc play`. Built the NixOS-native way, shaped after the
     [zbotic guide](https://zbotic.in/blogs/raspberry-pi-internet-radio-build-an-always-on-music-player/)
     the user linked, over the Pi Zero W's **onboard Bluetooth** (BCM43438 combo chip) to a Bluetooth
     speaker rather than a USB DAC, since the onboard radio already does WiFi *and* Bluetooth and the
     user wants to use that directly.

  Both parts need to be completed and verified, not just Part 1 with Part 2 scaffolded for later.
- **Reusability:** the base NixOS image (Part 1) must stay independent of the radio project (Part 2) —
  the radio lives as a self-contained example under `example/radio/`, imported as an optional extra
  module rather than baked into `devices/rpi-zero-w/configuration.nix`. The user is considering splitting
  this into its own repo later; keeping it in one repo for now is explicitly for faster
  iteration/validation, but the module boundary should already make that future split easy (no
  radio-specific bits leaking into the base device config).
- **Config style:** flake-based (user's first time with flakes, so the plan keeps the flake itself small
  and legible).
- **Secrets:** not sops-nix/agenix — a plain **gitignored `.nix` file** imported by the flake, holding the
  WiFi PSK and SSH authorized keys, with a tracked `.example` template. (A literal `.env` file can't be
  natively imported by Nix eval without extra parsing glue; a gitignored `.nix` file gets the same
  "nothing sensitive committed" property while staying a one-line `import`.)

## File layout

```
README.md                              # repo overview, points at example/radio/README.md, credits sources
flake.nix                              # inputs (nixpkgs), nixosConfigurations.{rpi-zero-w, rpi-zero-w-radio}
devices/rpi-zero-w/
  configuration.nix                    # base: boot loader, kernel, firmware, networking, ssh, users, GPIO/I2C
  secrets.nix.example                  # tracked template: { wifi = { ssid, psk }; sshAuthorizedKeys = [...]; }
  secrets.nix                          # gitignored, real values, imported by configuration.nix
example/radio/
  README.md                            # what this is, sources/credits, how to build+flash+run, station config
  module.nix                           # services.mpd core, station playlists
  bluetooth.nix                        # onboard BT (btattach) + BlueALSA -> mpd audio_output wiring
```

`example/radio/` is only ever composed on top of the base `devices/rpi-zero-w/configuration.nix` in the
flake — it never modifies or duplicates anything from Part 1, so a future split-out repo only needs to
move this one directory (plus depend on wherever the base config ends up).

Add `devices/rpi-zero-w/secrets.nix` to `.gitignore` (the repo already has broad `.env`/`*secrets*`-style
ignore conventions near the existing `.env` entries — follow that pattern).

## `flake.nix`

- Single input: `nixpkgs` (pin to `nixos-unstable` or a recent stable release — recommend unstable since
  armv6l fixes land there first and this is already an unsupported-tier build).
- Part 1 output — the reusable base image:
  `nixosConfigurations.rpi-zero-w = nixpkgs.lib.nixosSystem { system = "x86_64-linux"; modules = [ ... devices/rpi-zero-w/configuration.nix ]; }`
  with `nixpkgs.crossSystem.system = "armv6l-linux"` set inside a module, so the build host stays
  `x86_64-linux` (their main machine) while the produced system targets armv6l. This is "just the OS,
  boots and is SSH-reachable" — nothing app-specific.
- Part 2 output — the working radio appliance:
  `nixosConfigurations.rpi-zero-w-radio`, composing `devices/rpi-zero-w/configuration.nix` +
  `example/radio/module.nix` + `example/radio/bluetooth.nix`.
- Expose the SD image as a flake output so building either is one command, e.g.:
  `nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage`

## `devices/rpi-zero-w/configuration.nix`

- `boot.loader.grub.enable = false; boot.loader.generic-extlinux-compatible.enable = true;` — the
  non-deprecated path (see Context above), *not* `boot.loader.raspberryPi`.
- Firmware partition populated by `sdImage.populateFirmwareCommands`, modeled on nixpkgs'
  `sd-image-aarch64.nix` but retargeted at armv6l: copy `bootcode.bin`/`fixup*.dat`/`start*.elf` from
  `pkgs.raspberrypifw`, copy `${pkgs.ubootRaspberryPiZero}/u-boot.bin` in as `kernel.img`, and write a
  `config.txt` with `kernel=kernel.img` (no `arm_64bit=1` — this board is 32-bit) plus `enable_uart=1`.
  U-Boot then picks up the `extlinux.conf` that `generic-extlinux-compatible` writes to the NixOS
  partition, same mechanism as the 64-bit Pis just for this board's U-Boot target.
- `boot.kernelPackages = pkgs.linuxPackages_rpi0;` — verify this attribute still exists in the pinned
  nixpkgs revision when implementing; fall back to whatever the current rpi0-target kernel package is
  named if renamed.
- `boot.initrd.includeDefaultModules = false;` with only the modules actually needed
  (`["ext4" "mmc_block"]`) to keep the initrd build small — a trick from the reference repo that avoids
  pulling in unrelated driver builds on this slow-to-build target.
- `hardware.enableRedistributableFirmware = false;` + `hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];`
- Enable I2C/SPI via `hardware.deviceTree` overlays (`dtparam=i2c_arm=on,spi=on` equivalents) rather than
  a `config.txt` `dtoverlay=` line, since with `boot.loader.raspberryPi` gone there's no NixOS-managed
  `firmwareConfig` option writing to `config.txt` anymore — `hardware.deviceTree` is the mechanism that
  still applies with `generic-extlinux-compatible`. Enabled now, unused until a hardware project needs
  it. Flag to the user during implementation if `/dev/i2c-*` doesn't appear (a documented unresolved
  rough edge for this board in the NixOS Discourse thread) — treat as a known possible follow-up, not a
  blocker for getting the box booting and SSH-reachable.
- Networking: `networking.wireless.enable = true;` (wpa_supplicant, since NetworkManager is heavier and
  not needed for a single always-on WiFi headless box) configured from `secrets.nix`'s
  `wifi.ssid`/`wifi.psk` via `networking.wireless.networks.<ssid>.psk`.
- `services.openssh.enable = true;` with `users.users.<user>.openssh.authorizedKeys.keys` sourced from
  `secrets.nix`'s `sshAuthorizedKeys` list. Password auth off.
- Keep `environment.systemPackages` minimal at first boot (just what's needed to confirm the box is
  alive) — anything not baked into the image will have to build/fetch on-device later, which is
  impractical on a 512MB single-core board with no cache, so prefer adding packages to the image and
  rebuilding/reflashing over installing on-device.

## `example/radio/module.nix` — MPD core

Following the shape of the zbotic guide, but the NixOS-native way:

- `services.mpd.enable = true;` with `services.mpd.musicDirectory`/`playlistDirectory` under
  `/var/lib/mpd` (module-managed, no manual `apt install`/`/etc/mpd.conf` editing needed).
- `services.mpd.network.listenAddress = "any";` so `mpc`/an MPD client can reach it from the LAN, mirror
  of the guide's `bind_to_address "any"`.
- Station playlists as `.m3u` files under the MPD playlist directory (declaratively written via
  `environment.etc` or a `systemd.tmpfiles.rules` drop-in at activation, rather than the guide's
  `sudo tee` at the shell) — ask the user for the actual station stream URL(s) they want when
  implementing, the guide's BBC World Service example is just a placeholder.
- Control: `pkgs.mpc-cli` in `environment.systemPackages` for manual `mpc play`/`mpc next` over SSH as a
  debugging aid; the guide's OLED/buttons/web-UI options are explicitly out of scope per the user's
  answer above, but the GPIO/I2C enablement already in the base `configuration.nix` leaves room for that
  later without a rebuild-from-scratch.
- **Autoplay on boot is a hard requirement, not optional:** `services.mpd` starting is not enough by
  itself — add a `systemd.services.radio-autoplay` (`wantedBy = [ "multi-user.target" ]`,
  `after = [ "mpd.service" "bluetooth-connect.service" ]` — see `bluetooth.nix` — `wants` on the same,
  `ExecStart` running `mpc clear && mpc load <configured station> && mpc play` via `pkgs.mpc-cli`) so the
  box starts playing the configured stream unattended, matching "plug it in and it plays" from the
  zbotic guide's whole premise. Needs to tolerate MPD/Bluetooth not being ready yet on first boot
  (`Restart=on-failure` with a short `RestartSec`, or an explicit wait-for-mpd-socket step) rather than
  running once and giving up.
- Does **not** set `services.mpd.extraConfig`'s `audio_output` itself — that's `bluetooth.nix`'s job, kept
  separate so the MPD core doesn't need to know or care how audio actually gets out.

## `example/radio/bluetooth.nix` — onboard Bluetooth → BT speaker

- The Pi Zero W's BCM43438 combo chip exposes Bluetooth over UART, same as the Pi 3 — reuse the NixOS
  wiki's documented `btattach` recipe (`systemd.services.btattach`, `ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000"`,
  `after = [ "dev-ttyAMA0.device" ]`) since that's the known-working way to bring the UART-attached
  controller up before `bluetooth.service` starts.
- `hardware.bluetooth.enable = true;` for BlueZ.
- Audio bridge: `pkgs.bluez-alsa` (BlueALSA) rather than PipeWire — PipeWire's Bluetooth support is the
  more modern default on beefier boards, but BlueALSA is the lighter-weight, commonly recommended option
  for a headless single-core/512MB board like this one. Runs as a small systemd service exposing the
  paired speaker as an ALSA PCM device.
- `services.mpd.extraConfig`'s `audio_output { type "alsa"; device "bluealsa:DEV=<speaker MAC>,PROFILE=a2dp"; }`
  once the speaker's MAC is known.
- **Pairing vs. reconnecting are different problems.** Pairing is an unavoidable one-time manual step over
  SSH (`bluetoothctl` → `scan on`, `pair <MAC>`, `trust <MAC>`) — no way to automate first-time pairing
  without knowing the specific speaker, so the README documents the `bluetoothctl` steps. But
  *reconnecting* to an already-trusted/paired speaker on every subsequent boot must be automatic (that's
  part of the "just works on boot" requirement) — add `systemd.services.bluetooth-connect`
  (`after = [ "bluetooth.service" "btattach.service" ]`, `before = [ "radio-autoplay.service" ]`,
  `ExecStart` running `${pkgs.bluez}/bin/bluetoothctl connect <speaker MAC>`, with retry/backoff since the
  speaker may power on slightly after the Pi) so `module.nix`'s autoplay unit has something to actually
  order itself after.

## READMEs and credits

- **Root `README.md`:** short repo overview — what this is (NixOS on an original Pi Zero W), the
  cross-compilation/no-binary-cache constraint, how `devices/rpi-zero-w/` (base image) relates to
  `example/radio/` (optional add-on, self-contained on purpose), and a pointer into
  `example/radio/README.md` for the radio-specific instructions. Includes base-image build/flash/first-boot
  steps (WiFi/SSH setup via `secrets.nix`).
- **`example/radio/README.md`:** what it is, why it's split out (reusable module now, easy to extract into
  its own repo later), how `module.nix` (MPD + autoplay) and `bluetooth.nix` (pairing/reconnect + audio
  output) fit together, the build/flash command for `nixosConfigurations.rpi-zero-w-radio`, how to set the
  station stream URL, and the one-time manual `bluetoothctl` pairing steps (with a note that reconnect on
  every subsequent boot is automatic).
- **Credit sources** explicitly in both READMEs (a "Sources / credits" section), since this plan leans
  directly on prior art:
  - [NixOS Wiki — NixOS on ARM/Raspberry Pi](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi) —
    boot-process background, the `btattach`/Bluetooth recipe, device tree overlay guidance.
  - [cyber-murmel/nixos-rpi-zero-w](https://github.com/cyber-murmel/nixos-rpi-zero-w) — original working
    reference for this exact board (predates the `boot.loader.raspberryPi` deprecation, adapted here).
  - [NixOS Discourse — "NixOS on raspberry pi zero w"](https://discourse.nixos.org/t/nixos-on-raspberry-pi-zero-w/38018) —
    armv6 cross-compile pitfalls (`llvmPackages_14`, `-latomic`), unresolved I2C rough edge.
  - [nixpkgs PR #241534](https://github.com/NixOS/nixpkgs/pull/241534) — deprecation of
    `boot.loader.raspberryPi`, rationale for the `generic-extlinux-compatible` + U-Boot replacement.
  - [zbotic — Raspberry Pi Internet Radio: Build an Always-On Music Player](https://zbotic.in/blogs/raspberry-pi-internet-radio-build-an-always-on-music-player/) —
    shape of the MPD-based radio project this reimplements declaratively.

## Build & flash

1. `nix build .#nixosConfigurations.rpi-zero-w.config.system.build.sdImage` for the Part 1 base image, or
   `nix build .#nixosConfigurations.rpi-zero-w-radio.config.system.build.sdImage` for the Part 2 radio
   appliance. Expect a long first build for each — no binary cache for this architecture.
2. Decompress and write: `zstd -dcf result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=64k status=progress`
   (confirm the correct device before writing).
3. Boot the Pi, wait for it to join WiFi, find its address (router DHCP lease list or `avahi`/mDNS if
   enabled), `ssh` in with the key from `secrets.nix`.
4. Radio image only, one-time: pair the Bluetooth speaker over SSH via `bluetoothctl` per
   `example/radio/README.md` before expecting audio out.

## Verification

Both parts are required deliverables — Part 2 is not "if there's time."

- **Part 1:** confirm the base image builds via the `nix build` command above; boot the physical Pi Zero
  W from the flashed card and confirm it associates to WiFi and becomes SSH-reachable. This is the actual
  pass/fail signal — there's no way to verify armv6l boot behavior without the real hardware. If I2C/SPI
  don't appear as `/dev/i2c-*`/`/dev/spidev*` after boot, note it as a known follow-up rather than
  blocking on it, per the unresolved report in the community thread — it doesn't affect Part 1's actual
  requirements (boot + SSH).
- **Part 2:** confirm the radio image builds; boot it, pair the Bluetooth speaker once via `bluetoothctl`,
  power-cycle the Pi, and confirm that — with zero manual intervention after the pairing step — it
  reconnects to the speaker and starts playing the configured stream automatically. Check
  `systemctl status bluetooth-connect radio-autoplay mpd` over SSH if it doesn't. This unattended-restart
  behavior, not just "audio plays after I run `mpc play` by hand," is the actual bar for Part 2 being done.
