{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.seafile;
in {

  options.pinpox.services.seafile = {
    enable = mkEnableOption "seafile server";
  };

  config = mkIf cfg.enable {

    services.seafile = {
      enable = true;

      # https://manual.seafile.com/config/seafile-conf/
      seafileSettings = {
        fileserver = {
          port = 8082;
          host = "127.0.0.1";
        };
      };

      # https://manual.seafile.com/config/ccnet-conf/

      ccnetSettings = { General.SERVICE_URL = "https://seafile.pablo.tools"; };

      adminEmail = "seafile@pablo.tools";

      # https://manual.seafile.com/config/seahub_settings_py/
      # seahubExtraConf = '' '';

      # initialAdminPassword = "somepass";

    };

    systemd.services = {
      seaf-server.serviceConfig.EnvironmentFile =
        [ "/var/secrets/seafile/seaf-server-env" ];
      seahub.serviceConfig.EnvironmentFile =
        [ "/var/secrets/seafile/seahub-env" ];
    };
  };
}
