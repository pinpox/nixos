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
      "restic/credentials" = { };
      "restic/repo-pw" = { };
    };

    services.restic.backups =
      let
        host = config.networking.hostName;
      in
      {
        s3-pinpox = {
          paths = [ "/home/pinpox/Notes/" ];
          repository = "s3:https://vpn.s3.pablo.tools/restic";
          environmentFile = "${config.lollypops.secrets.files."restic/credentials".path}";
          passwordFile = "${config.lollypops.secrets.files."restic/repo-pw".path}";
          backupCleanupCommand = ''
            if [ $EXIT_STATUS -ne 0 ]; then
              ${pkgs.curl}/bin/curl -u $NTFY_USER:$NTFY_PASS \
              -H 'Title: Backup on ${host} failed!' \
              -H 'Tags: backup,borg,${host}' \
              -d "Restic backup error on ${host}!" 'https://push.pablo.tools/pinpox_backups'
            else
              ${pkgs.curl}/bin/curl -u $NTFY_USER:$NTFY_PASS \
              -H 'Title: Backup on ${host} successful!' \
              -H 'Tags: backup,borg,${host}' \
              -d "Restic backup success on ${host}!" 'https://push.pablo.tools/pinpox_backups'
            fi
          '';
        };
      };
  };
}
