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
  mkPres = JITSI_ROOMS: JITSI_SERVER: ROOM_ID: port: {

    wantedBy = [ "multi-user.target" ];
    environment = {
      inherit JITSI_ROOMS JITSI_SERVER ROOM_ID;
      HOMESERVER_URL = "https://matrix.org";
      USER_ID = "@alertus-maximus:matrix.org";
      LISTEN_ADDRESS = "0.0.0.0:${port}";
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

in
{

  options.pinpox.services.jitsi-matrix-presence = {
    enable = mkEnableOption "Jitsi presence notification service";
  };

  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [
      8226
      8227
      8228
    ];

    clan.core.vars.generators."jitsi-presence" = pinpox-utils.mkEnvGenerator [ "ACCESS_TOKEN" ];

    systemd.services.jitsi-matrix-presence-krebs =
      mkPres "krebs,nixos" "https://jitsi.lassul.us" "!bohcSYPVoePqBDWlvE:hackint.org"
        "8226";

    systemd.services.jitsi-matrix-presence =
      mkPres "clan.lol,space" "https://jitsi.lassul.us" "!HlSSgpBfhsKrEmqAtE:matrix.org"
        "8227";

  };
}
