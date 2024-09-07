{
  config,
  lib,
  radio,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.radio;
in
{

  options.pinpox.services.radio = {
    enable = mkEnableOption "web radio streamer";

    host = mkOption {
      type = types.str;
      default = "radio.0cx.de";
      description = "Host serving the radio";
      example = "radio.0cx.de";
    };

  };

  config = mkIf cfg.enable {

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig = "reverse_proxy 127.0.0.1:7000";
    };

    systemd.services.radio =
      let
        stationsfile = pkgs.writeTextFile {
          name = "stations.ini";
          text = ''
            [Hirschmilch Psytrance]
            url = "https://hirschmilch.de:7000/psytrance.mp3"

            [Hirschmilch Progressive]
            url = "https://hirschmilch.de:7000/progressive.mp3"

            [Lassulus Radio]
            url = "https://radio.lassul.us/music.mp3"
          '';
        };

      in
      {
        wantedBy = [ "multi-user.target" ];
        environment = {
          RADIO_ADDRESS = "127.0.0.1:7000";
          RADIO_STATIONFILE = stationsfile;
          GIN_MODE = "release";
        };
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${radio.packages.x86_64-linux.default}/bin/radio";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
  };
}
