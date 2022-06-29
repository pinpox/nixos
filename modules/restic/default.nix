{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.restic-client;
in
{

  options.pinpox.services.restic-client = {
    enable = mkEnableOption "restic backups";
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files = {
      "restic/s3-credentials" = { };
      "restic/repo-pw" = { };
    };

    services.restic.backups = {
      s3-pinpox = {
        paths = [ "/home/pinpox/Notes/" ];
        repository = "s3:https://vpn.s3.pablo.tools/restic";
        environmentFile = "${config.lollypops.secrets.files."restic/s3-credentials".path}";
        passwordFile = "${config.lollypops.secrets.files."restic/repo-pw".path}";
      };
    };
  };
}
