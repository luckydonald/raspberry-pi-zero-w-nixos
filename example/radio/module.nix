# MPD core for the internet radio example: the daemon plus the "just start playing on boot"
# behavior. Output-agnostic on purpose — see bluetooth.nix for how audio actually gets out.
{ config, pkgs, lib, ... }:

let
  # Change this to whatever stream you want the radio to play on boot.
  stationUrl = "https://stream.live.vc.bbcmedia.co.uk/bbc_world_service";
in
{
  services.mpd.enable = true;
  services.mpd.settings.bind_to_address = "any";
  # Listening on "any" is deliberate (so `mpc`/an MPD client can reach it from the LAN, not
  # just localhost) — open the firewall to match instead of leaving it unreachable.
  services.mpd.openFirewall = true;
  services.mpd.user = "mpd";
  services.mpd.group = "mpd";

  # Trim MPD's feature set instead of building nixpkgs' default, which enables essentially
  # everything on Linux — pipewire/jack/pulse outputs, WebDAV/NFS/SMB/optical-disc input,
  # fluidsynth/game-music-emu/tracker-module decoders, API docs — none of which an internet
  # radio appliance over ALSA/BlueALSA needs, and which multiplies cross-build time on this
  # already-slow armv6l target for no benefit. This also sidesteps a real build failure: the
  # default set's `ffmpeg` feature pulls in `x265` (a video codec — MPD is audio-only), and
  # x265's nixpkgs derivation currently fails to apply one of its patches cleanly, unrelated to
  # anything in this config. Kept generous on actual stream-format decoders (mp3/aac/ogg/opus/
  # flac) since "whatever internet radio stream someone points this at" isn't predictable.
  #
  # `services.mpd` has no package option — the module hardcodes `pkgs.mpd` — so this is applied
  # as an overlay instead. Scoped to this file/module, so it only affects the radio image, not
  # the base image (which doesn't import this file at all).
  nixpkgs.overlays = [
    (final: prev: {
      mpd = prev.mpd.override {
        features = [
          "curl" # HTTP(S) stream URLs — the whole point
          "mpg123"
          "mad"
          "faad" # AAC/HE-AAC — common for internet radio
          "flac"
          "vorbis"
          "opus"
          "id3tag"
          "alsa" # our only output path (direct, or via BlueALSA)
          "soxr" # resampling quality
          "sqlite"
          "icu"
          "expat" # playlist format parsing
          "dbus"
          "zeroconf"
          "systemd"
        ];
      };
    })
  ];

  environment.systemPackages = [ pkgs.mpc ];

  # `services.mpd` only starts the daemon — it doesn't queue or play anything by itself.
  # This is what makes it an actual "plug it in and it plays" radio instead of a player
  # waiting for someone to run `mpc play` over SSH.
  systemd.services.radio-autoplay = {
    description = "Start MPD playing the configured radio stream";
    after = [ "mpd.service" "bluetooth-connect.service" ];
    wants = [ "mpd.service" "bluetooth-connect.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # mpd and the Bluetooth reconnect can both take a few seconds after their units report
      # "started" (socket not accepting yet / speaker not paired yet) — retry instead of
      # failing once and giving up.
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "radio-autoplay" ''
        set -eu
        ${pkgs.mpc}/bin/mpc clear
        ${pkgs.mpc}/bin/mpc add "${stationUrl}"
        ${pkgs.mpc}/bin/mpc play
      '';
    };
  };
}
