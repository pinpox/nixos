{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.minio;
in
{

  options.pinpox.services.minio = { enable = mkEnableOption "mino s3 config"; };

  config = mkIf cfg.enable {

    lollypops.secrets.files."minio/env" = { };

    networking.firewall.interfaces.wg0.allowedTCPPorts = [
      9000
      9001
    ];

    services.minio = {
      enable = true;
      listenAddress = "${config.pinpox.wg-client.clientIp}:9000";
      consoleAddress = "${config.pinpox.wg-client.clientIp}:9001";
      region = "eu-central-1";
      rootCredentialsFile = "${config.lollypops.secrets.files."minio/env".path}";
      dataDir = [ "/mnt/data/minio/data" ];
      configDir = "/mnt/data/minio/config";
    };

    systemd.services.minio = {

      environment = {
        MINIO_SERVER_URL = "https://vpn.s3.pablo.tools";
        MINIO_BROWSER_REDIRECT_URL = "https://vpn.minio.pablo.tools";
      };
    };
  };
}
