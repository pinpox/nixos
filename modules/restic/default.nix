{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.restic-client;
in
{

  options.pinpox.services.restic-client = {
    enable = mkEnableOption "restic backups";
  };

  config = mkIf cfg.enable {

    services.restic.backups = {
      s3-pinpox = {
        paths = [ "/home/pinpox/Notes/" ];
        repository = "s3:https://vpn.s3.pablo.tools/restic";
        environmentFile = "/var/src/secrets/restic/s3-credentials";
        passwordFile = "/var/src/secrets/restic/repo-pw";
      };
    };
  };
}
