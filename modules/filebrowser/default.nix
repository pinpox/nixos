{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.filebrowser;
in
{

  options.pinpox.services.filebrowser = {
    enable = mkEnableOption "filebrowser webUI";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.filebrowser = {
      isSystemUser = true;
      home = "/var/lib/filebrowser";
      description = "filebrowser system user";
      extraGroups = [ "filebrowser" ];
      createHome = true;
    };

    users.groups.filebrowser = {
      name = "filebrowser";
    };

    # Service
    systemd.services.filebrowser = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start filebrowser";
      environment = {
        FB_ADDRESS = "192.168.8.4";
        FB_PORT = 8787;
        FB_SIGNUP = false;
      };
      serviceConfig = {
        EnvironmentFile = [ config.secrets.files."filebrowser/envfiles".path ];
        # Environment = [ ];
        WorkingDirectory = "/var/lib/filebrowser";
        User = "filebrowser";
        ExecStart = "${pkgs.filebrowser}/bin/filebrowser";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # TODO Reverse proxy
  };
}
