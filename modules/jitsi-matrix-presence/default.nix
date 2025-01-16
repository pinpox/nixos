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
  };

  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [
      8226
      8227
    ];

    # krebs channel
    clan.core.vars.generators."jitsi-presence-krebs" = pinpox-utils.mkEnvGenerator [
      "ACCESS_TOKEN"
      "ROOM_ID"
    ];

    systemd.services.jitsi-matrix-presence-krebs = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOMESERVER_URL = "https://matrix.org";
        LISTEN_ADDRESS = "0.0.0.0:8226";
        USER_ID = "@alertus-maximus:matrix.org";
        JITSI_ROOMS = "krebs,nixos";
        JITSI_SERVER = "https://jitsi.lassul.us";
      };

      serviceConfig = {
        EnvironmentFile = [
          config.clan.core.vars.generators."jitsi-presence-krebs".files."envfile".path
        ];
        DynamicUser = true;
        ExecStart = "${jitsi-matrix-presence.packages.x86_64-linux.default}/bin/jitsi-presence";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # clan channel
    clan.core.vars.generators."jitsi-presence" = pinpox-utils.mkEnvGenerator [
      "ACCESS_TOKEN"
      "ROOM_ID"
    ];

    systemd.services.jitsi-matrix-presence = {
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
