{
  config,
  lib,
  pkgs,
  pinpox-utils,
  twitch-first,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.twitch-first;
in
{

  options.pinpox.services.twitch-first = {
    enable = mkEnableOption "Twitch 'first' channel point redemption tracker";
  };

  config = mkIf cfg.enable {

    clan.core.vars.generators."twitch-first" = pinpox-utils.mkEnvGenerator [
      "TWITCH_CLIENT_ID"
      "TWITCH_CLIENT_SECRET"
      "TWITCH_CHANNEL"
      "TWITCH_REWARD_ID"
    ];

    systemd.services.twitch-first = {
      description = "Twitch first channel point tracker";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = "${twitch-first.packages.${pkgs.system}.twitch-first}/bin/twitch-first";
        EnvironmentFile = config.clan.core.vars.generators."twitch-first".files."envfile".path;
        DynamicUser = true;
        StateDirectory = "twitch-first";
        WorkingDirectory = "/var/lib/twitch-first";
        Restart = "on-failure";
        RestartSec = 10;
      };

      environment = {
        TWITCH_FIRST_DB = "/var/lib/twitch-first/firsts.db";
        TWITCH_TOKEN_FILE = "/var/lib/twitch-first/token.json";
      };
    };
  };
}
