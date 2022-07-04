{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.filebrowser;

in
{

  options.pinpox.services.filebrowser = {
    enable = mkEnableOption "filebrowser webUI";
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files."filebrowser/envfile" = { };

    # User and group
    users.users.filebrowser = {
      isSystemUser = true;
      home = "/var/lib/filebrowser";
      description = "filebrowser system user";
      extraGroups = [ "filebrowser" ];
      createHome = true;
    };

    users.groups.filebrowser = { name = "filebrowser"; };

    # Service
    systemd.services.filebrowser = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start filebrowser";
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
