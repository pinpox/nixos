{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.minio;
in
{

  options.pinpox.services.minio = {
    enable = mkEnableOption "minio s3 config";
  };

  config = mkIf cfg.enable {

    clan.core.vars.generators."minio" = rec {
      files.root-credentials = { };
      validation.script = script;

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];

      script = # sh
        ''
          mkdir -p $out
          printf "MINIO_ROOT_USER=admin\nMINIO_ROOT_PASSWORD='%s'" "$(xkcdpass -d-)" > $out/root-credentials
        '';
    };

    networking.firewall.interfaces.wg-clan.allowedTCPPorts = [
      9000
      9001
    ];

    services.minio =

      let
        wg-clan-ip = builtins.elemAt (builtins.match "(.*)/.*" (builtins.elemAt config.networking.wireguard.interfaces.wg-clan.ips 0)) 0;

      in
      {
        enable = true;
        listenAddress = "${wg-clan-ip}:9000";
        consoleAddress = "${wg-clan-ip}:9001";
        region = "eu-central-1";
        rootCredentialsFile = "${config.clan.core.vars.generators."minio".files."root-credentials".path}";
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
