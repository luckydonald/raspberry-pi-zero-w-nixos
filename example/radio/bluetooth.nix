# Onboard Bluetooth (BCM43438 combo chip, same as the Pi 3) -> A2DP Bluetooth speaker.
#
# Three layers, in start order: bring the UART-attached controller up (btattach) -> BlueZ
# (hardware.bluetooth) -> bridge BlueZ audio to an ALSA PCM device (BlueALSA) that MPD can
# target directly. Reconnecting to an already-paired speaker on every boot is automated;
# the initial pairing is a one-time manual step (see ../../example/radio/README.md).
{ config, pkgs, lib, ... }:

let
  # Set this to the MAC address of your speaker after pairing it once (see README).
  speakerMac = "AA:BB:CC:DD:EE:FF";
in
{
  hardware.bluetooth.enable = true;

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
      ExecStart = "${pkgs.bluez}/bin/bluetoothctl connect ${speakerMac}";
    };
  };

  services.mpd.settings.audio_output = [
    {
      type = "alsa";
      name = "Bluetooth Speaker";
      device = "bluealsa:DEV=${speakerMac},PROFILE=a2dp";
    }
  ];
}
