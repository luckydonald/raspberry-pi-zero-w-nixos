# Onboard Bluetooth (BCM43438 combo chip, same as the Pi 3) -> A2DP Bluetooth speaker.
#
# Three layers, in start order: bring the UART-attached controller up (btattach) -> BlueZ
# (hardware.bluetooth) -> bridge BlueZ audio to an ALSA PCM device (BlueALSA) that MPD can
# target directly. Reconnecting to an already-paired speaker on every boot is automated;
# the initial pairing is a one-time manual step (see ../../example/radio/README.md).
{ config, pkgs, lib, ... }:

let
  # bluetooth-speaker-mac ships with explanatory `#` comment lines above the actual value (see
  # populateFirmwareCommands below) — strip comments/blank lines and take the last real line,
  # rather than a bare `cat` that would swallow the comments into the "MAC" too.
  readSpeakerMac = "grep -vE '^[[:space:]]*(#|$)' /boot/firmware/bluetooth-speaker-mac | tail -n1 | tr -d '[:space:]'";
in
{
  hardware.bluetooth.enable = true;

  # Like WiFi/SSH/the station URL, the speaker's MAC is personal-device data that doesn't belong
  # baked into a publishable image — read from the boot partition at runtime instead. Ships a
  # placeholder; the actual value gets written there after pairing (see README).
  sdImage.populateFirmwareCommands = ''
    cat > firmware/bluetooth-speaker-mac << 'EOF'
    # After pairing your speaker once (see example/radio/README.md — `bluetoothctl pair`/`trust`),
    # replace the line below with its MAC address, e.g. AA:BB:CC:DD:EE:FF (as shown by
    # `bluetoothctl devices` or `bluetoothctl info <mac>`), then boot or reboot the Pi.
    AA:BB:CC:DD:EE:FF
    EOF
  '';

  # Two cross-compile gaps in nixpkgs' bluez-alsa derivation, neither specific to this config:
  # 1. `glib` is only in buildInputs (target/armv6l), so `configure` can't find `gdbus-codegen`,
  #    which has to run on the build host, not the target — fixed by adding glib for the build
  #    platform.
  # 2. `systemdLibs` is listed in nativeBuildInputs instead of buildInputs, so the target-arch
  #    systemd pkg-config file it needs to link against isn't actually visible to `configure`
  #    when cross-compiling (`checking for systemd >= 200... no`). We don't need bluez-alsa's
  #    own bundled systemd integration anyway — bluealsa is run via our own systemd unit below
  #    — so disabling it sidesteps the broken check entirely rather than working around it.
  nixpkgs.overlays = [
    (final: prev: {
      bluez-alsa = (prev.bluez-alsa.override { systemdSupport = false; }).overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.buildPackages.glib ];
      });
    })
  ];

  # The Pi Zero W's Bluetooth controller hangs off a UART, not USB — it needs to be attached
  # explicitly before bluetooth.service has anything to talk to. Recipe from the NixOS wiki's
  # Raspberry Pi page (originally documented for the Pi 3, same combo chip).
  systemd.services.btattach = {
    description = "Attach the onboard Bluetooth controller (UART)";
    before = [ "bluetooth.service" ];
    after = [ "dev-ttyAMA0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
      Restart = "on-failure";
    };
  };

  systemd.services.bluealsa = {
    description = "BlueALSA - bridge BlueZ audio to ALSA";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez-alsa}/bin/bluealsa -p a2dp-source";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Pairing a speaker (bluetoothctl `pair`/`trust`) only has to happen once — BlueZ remembers
  # trusted devices across reboots. But it does NOT reconnect to them automatically on its own,
  # so without this the radio would need someone to run `bluetoothctl connect` by hand after
  # every power cycle. This is what makes the reconnect part of "boots and just plays" too.
  systemd.services.bluetooth-connect = {
    description = "Reconnect to the paired radio Bluetooth speaker";
    after = [ "bluetooth.service" "bluealsa.service" ];
    wants = [ "bluetooth.service" "bluealsa.service" ];
    before = [ "radio-autoplay.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # The speaker may power on slightly after the Pi, or still be waking up its radio —
      # retry rather than failing once.
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "bluetooth-connect" ''
        set -eu
        mac=$(${readSpeakerMac})
        ${pkgs.bluez}/bin/bluetoothctl connect "$mac"
      '';
    };
  };

  # MPD's `audio_output` is Nix-evaluated (baked at build time, same as everything else here) —
  # there's no runtime-templating mechanism for it like the wireless module's environmentFile.
  # So MPD gets a fixed, generic ALSA device name ("btspeaker") instead of the real MAC, and a
  # separate unit resolves that name to the actual paired speaker via /etc/asound.conf, written
  # fresh at every boot from the boot partition. This keeps MPD's own (published, public) config
  # free of personal data while still routing audio to the right device at runtime.
  systemd.services.bluetooth-asound-config = {
    description = "Write /etc/asound.conf pointing \"btspeaker\" at the configured Bluetooth speaker";
    before = [ "mpd.service" "bluetooth-connect.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "bluetooth-asound-config" ''
        set -eu
        mac=$(${readSpeakerMac})
        cat > /etc/asound.conf << EOF
        pcm.btspeaker {
          type plug
          slave.pcm {
            type bluealsa
            device "$mac"
            profile "a2dp"
          }
        }
        EOF
      '';
    };
  };

  services.mpd.settings.audio_output = [
    {
      type = "alsa";
      name = "Bluetooth Speaker";
      device = "btspeaker";
    }
  ];
}
