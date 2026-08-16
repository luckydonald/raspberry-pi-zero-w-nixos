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
