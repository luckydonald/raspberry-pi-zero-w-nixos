# Publishable images: move all personal config to the boot partition, add GitHub Releases

## Context

Both `nixosConfigurations` (`rpi-zero-w`, `rpi-zero-w-radio`) already build successfully end to
end (verified via real `nix build`, see repo history and memory). The user now wants the built
`.img.zst` published as GitHub Release assets — and correctly flagged a problem: the current
design bakes WiFi PSK and SSH keys into `devices/rpi-zero-w/secrets.nix` at **Nix build time**,
which means they end up literally embedded in the built system's `/nix/store` — which ships
*inside* the image. Publishing that image publicly would leak them. Switching the secrets file
from `.nix` to `.env` (the user's first instinct) wouldn't fix this: the problem is *when* the
secret enters the system (build time, baked in), not what file format it started in on the build
host. The same issue applies to the radio's `stationUrl` (module.nix) and Bluetooth
`speakerMac` (bluetooth.nix) — both currently build-time `let` bindings, meaning a published
radio image would either play a fixed stream nobody else wants or fail to connect to anyone
else's speaker.

**Decided approach (confirmed with the user):** move all four values — WiFi SSID+PSK, SSH
authorized keys, radio station URL, Bluetooth speaker MAC — off the Nix-build-time path entirely
and onto the SD card's FAT **firmware partition** (mounted at `/boot/firmware`), read at
**runtime** by the running system instead. This partition stays writable/mountable from any OS
(Windows/Mac/Linux) after flashing — it's the same mechanism Raspberry Pi OS itself uses for its
well-known headless-setup convention (`wpa_supplicant.conf`/`ssh`/`userconf.txt` dropped onto the
boot partition before first boot), so the pattern should be recognizable to anyone flashing this.
The published image then contains **zero personal data** — the exact same build artifact is safe
to release publicly *and* is what gets flashed for personal use, fully personalized after
flashing rather than before building. This also means `devices/rpi-zero-w/secrets.nix` and the
whole `path:` vs bare `.#...` distinction (which existed *only* for this problem — see
`project_flake-eval-gitignored-secrets` memory) become unnecessary and should be removed.

## File-by-file changes

### `devices/rpi-zero-w/configuration.nix`

- **Remove** the `secrets = import (...)` `let` block and its two usages entirely.
- **WiFi:** NixOS's `networking.wireless.networks.<ssid>` can't help here — the SSID has to be a
  Nix attribute name, so it can't be deferred to runtime no matter what. Don't enable
  `networking.wireless` at all; instead run `wpa_supplicant` directly against a config file on
  the boot partition via a custom unit:
  ```nix
  systemd.services.wpa-supplicant-boot-partition = {
    description = "wpa_supplicant using /boot/firmware/wpa_supplicant.conf";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i wlan0 -c /boot/firmware/wpa_supplicant.conf";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  ```
  (verify at implementation time whether `wlan0` needs an explicit `After=`/device-unit ordering,
  and that default `networking.useDHCP` still picks up the interface once associated — likely
  yes, but worth confirming against the real board).
- **SSH:** replace `users.users.root.openssh.authorizedKeys.keys = secrets.sshAuthorizedKeys;`
  with pointing sshd's own `AuthorizedKeysFile` directive at the boot partition — a plain runtime
  file lookup sshd does itself, not something Nix reads at build time:
  ```nix
  services.openssh.settings.AuthorizedKeysFile = lib.mkForce "/boot/firmware/authorized_keys";
  ```
  (verify the exact current option surface — `services.openssh.settings.AuthorizedKeysFile` vs.
  a dedicated `services.openssh.authorizedKeysFiles` list option — nixpkgs has shuffled sshd
  option names before; use whichever is current).
- **Ship placeholder files** on the firmware partition via `sdImage.populateFirmwareCommands`
  (already used here for `bootcode.bin`/`u-boot.bin`/`config.txt` — add to the same derivation):
  a `wpa_supplicant.conf` with placeholder `ssid`/`psk` fields and a comment explaining what to
  edit, and an empty `authorized_keys` with a single `#` comment line explaining what to paste in.
  These are what a downloader of the public release edits before first boot; for the
  maintainer's own device, same process, just done once after flashing their own copy.

### `example/radio/module.nix`

- Remove the `let stationUrl = "...";` binding.
- `radio-autoplay`'s `ExecStart` script reads the URL from the boot partition instead:
  ```sh
  station_url=$(cat /boot/firmware/radio-station-url)
  mpc clear && mpc add "$station_url" && mpc play
  ```
- Contribute a `sdImage.populateFirmwareCommands` addition (this option should be mergeable
  across modules — verify) writing `/boot/firmware/radio-station-url`, pre-filled with the same
  BBC World Service URL already used as the working example throughout this project
  (`https://stream.live.vc.bbcmedia.co.uk/bbc_world_service`) — not a dummy placeholder. The
  radio image should play something real out of the box; editing this file is for picking a
  *different* station, not a required step to get any sound at all.

### `example/radio/bluetooth.nix`

- Remove the `let speakerMac = "...";` binding and stop putting the MAC directly into
  `services.mpd.settings.audio_output.device` (that option is Nix-evaluated/baked, same problem
  as before — no runtime-templating mechanism like the wireless module's `environmentFile`
  exists for MPD).
- Instead, decouple MPD's *baked* config (safe to publish, contains no personal data) from the
  *runtime* Bluetooth MAC via a local ALSA PCM alias:
  - `services.mpd.settings.audio_output` device becomes a fixed, generic string: `"btspeaker"`
    (just a local alias name, not personal data — safe to bake).
  - A new oneshot unit, ordered before `mpd.service` and `bluetooth-connect.service`, writes
    `/etc/asound.conf` at boot from the MAC read out of
    `/boot/firmware/bluetooth-speaker-mac`:
    ```
    pcm.btspeaker {
      type plug
      slave.pcm { type bluealsa; device "<mac from file>"; profile "a2dp"; }
    }
    ```
    (verify `/etc/asound.conf` is writable at runtime — i.e. nothing else declares
    `environment.etc."asound.conf"` that would make NixOS manage/symlink it immutably).
  - `bluetooth-connect.service`'s `ExecStart` also reads the MAC from the same file instead of
    the removed `let` binding.
- Contribute a `sdImage.populateFirmwareCommands` addition writing a placeholder
  `/boot/firmware/bluetooth-speaker-mac` (e.g. `AA:BB:CC:DD:EE:FF`, with a comment) — the
  existing README's `bluetoothctl pair`/`trust` instructions stay the same, just followed by
  editing this file with the paired MAC instead of a Nix rebuild.

### Removed

- `devices/rpi-zero-w/secrets.nix.example` and the `devices/rpi-zero-w/secrets.nix` gitignore
  entry — the boot-partition files are the new "template to copy/edit," shipped inside the image
  itself rather than in the repo.
- (Tell the user their local, gitignored `devices/rpi-zero-w/secrets.nix` is no longer read by
  anything — safe for them to delete, not deleting it automatically since it's their file.)

### New: `.github/workflows/release.yml`

Triggered on `push: tags: ["v*"]`. Reuses the same Cachix-warmed cache as
`nix-cache-warm.yml` (same `cachix-action` setup) so a release build mostly substitutes rather
than recompiles, assuming `flake.lock` hasn't drifted far since the last warm run. Builds both
`nixosConfigurations` sdImages, renames them (the derivation's default output filename doesn't
differentiate base vs radio — both would collide as literally the same name if uploaded as-is),
and attaches them to a GitHub Release matching the pushed tag via `gh release create` (already on
GitHub-hosted runners — no third-party release action needed, consistent with this repo's
existing workflows using official/minimal-dependency actions):

```sh
gh release create "$GITHUB_REF_NAME" \
  rpi-zero-w-base.img.zst \
  rpi-zero-w-radio.img.zst \
  --title "$GITHUB_REF_NAME" --generate-notes
```

Needs `permissions: contents: write` for the default `GITHUB_TOKEN` to create releases.

## Documentation updates

- **Root `README.md`:** replace the "First boot: WiFi & SSH" section — no more
  `secrets.nix.example` copy step. New flow: flash, mount the FIRMWARE partition on any computer,
  edit `wpa_supplicant.conf` and `authorized_keys`, eject, boot. Update/remove the "Binary cache"
  section's `path:` explanation (the whole reason it existed goes away — bare `nix build .#...`
  is now the *only* way this repo is built, locally or in CI, since nothing needs `secrets.nix`
  anymore). Add a note: re-flashing to a newer image resets the firmware partition to placeholder
  defaults again — back up the four edited files first if reflashing an already-configured
  device. Add a "Releases" section pointing at the new workflow / how to grab a prebuilt image.
- **`example/radio/README.md`:** update configuration instructions (station URL and speaker MAC
  are now boot-partition edits, not `module.nix`/`bluetooth.nix` edits) and the Bluetooth pairing
  section (pair via `bluetoothctl` as before, then write the MAC to
  `/boot/firmware/bluetooth-speaker-mac` instead of editing `bluetooth.nix`).
- Update `project_flake-eval-gitignored-secrets` memory to note it's superseded by this change
  (the `path:` workaround no longer applies to anything in this repo) — do this once the change
  lands, not part of the plan file itself.

## Verification

- `nix eval`/`nix build` both `nixosConfigurations` (bare `.#...`, no `path:` needed anymore) and
  confirm they succeed with the new boot-partition-reading units in place, same as before.
- Inspect the built firmware partition contents (mount the built `.img` or check
  `result/sd-image`) to confirm `wpa_supplicant.conf`, `authorized_keys`,
  `radio-station-url`, and `bluetooth-speaker-mac` actually land on it with sensible placeholder
  content.
- Flash + boot on real hardware, edit the four files with real values before first boot, confirm
  WiFi joins, SSH works, and (radio image) it starts playing the configured stream over the
  Bluetooth speaker at the configured MAC — same end-to-end bar as the original plan, just via
  the new configuration path.
- Push a test tag (or dry-run the workflow logic locally) to confirm `release.yml` produces two
  distinctly-named, downloadable assets on a GitHub Release.
