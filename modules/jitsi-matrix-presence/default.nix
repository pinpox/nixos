{
  config,
  lib,
  pkgs,
  jitsi-matrix-presence,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.jitsi-matrix-presence;
  pinpox-utils = import ../../utils { inherit pkgs; };
in
{

  options.pinpox.services.jitsi-matrix-presence = {
    enable = mkEnableOption "Jitsi presence notification service";

    # host = mkOption {
    #   type = types.str;
    #   default = "matrixpresence.0cx.de";
    #   description = "Host listening for webhooks";
    #   example = "hitme.0cx.de";
    # };

  };

  config = mkIf cfg.enable {

    # services.caddy = {
    #   enable = true;
    #   virtualHosts."${cfg.host}".extraConfig = "reverse_proxy 127.0.0.1:7000";
    # };

    clan.core.vars.generators."jitsi-presence" = pinpox-utils.mkEnvGenerator [
      "ACCESS_TOKEN"
      "ROOM_ID"
    ];

    systemd.services.jitsi-matrix-presence =
      let

      in
      {
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOMESERVER_URL = "https://matrix.org";
          LISTEN_ADDRESS = "0.0.0.0:8227";
          USER_ID = "@alertus-maximus:matrix.org";
          JITSI_ROOMS = "clan.lol,space";
          JITSI_SERVER = "https://jitsi.lassul.us";
        };

        serviceConfig = {
          EnvironmentFile = [
            config.clan.core.vars.generators."jitsi-presence".files."envfile".path
          ];
          DynamicUser = true;
          ExecStart = "${jitsi-matrix-presence.packages.x86_64-linux.default}/bin/jitsi-presence";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
  };
}
