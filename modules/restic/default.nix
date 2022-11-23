{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.restic-client;
in
{

  options.pinpox.services.restic-client = {
    enable = mkEnableOption "restic backups";

    backup-paths-onsite = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/Notes" ];
      description = "Paths to backup to onsite storage";
    };

    # TODO add contabo
    backup-paths-offsite = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/Notes" ];
      description = "Paths to backup to offsite storage";
    };

    backup-paths-exclude = mkOption {
      type = types.listOf types.str;
      default = [
        # "*.pyc"
        # "*/cache2"
        # "/*/.cache"
        # "/*/.go/pkg"
        # "/*/.config/Signal"
        # "/*/.local/share/Steam"
        # "/*/.config/chromium"
        # "/*/.rustup"
        # "/*/.config/discord"
        # "/*/.container-diff"
        # "/*/.gvfs/"
        # "/*/.local/share/Trash"
        # "/*/.mozilla/firefox"
        # "/*/.npm/_cacache"
        # "/*/.thumbnails"
        # "/*/.ts3client"
        # "/*/.vagrant.d"
        # "/*/.vim"
        # "/*/Cache"
        # "/*/Downloads"
        # "/*/Seafile"
        # "/*/.nextcloud"
        # "/*/code/nixpkgs"
        # "/*/code/vaultwarden"
        # "/*/code/github.com/pinpox/nixpkgs"
        # "/*/code/github.com/NixOS/nixpkgs"
        # "/*/VirtualBox VMs"
        # "discord/Cache"

      ];
      example = [ "/home/pinpox/cache" ];
      description = "Paths to exclude from backup";
    };
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files = {
      "restic/credentials" = { };
      "restic/repo-pw" = { };
    };

    services.restic.backups =
      let
        host = config.networking.hostName;
        script-post = ''
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

        restic-ignore-file = pkgs.writeTextFile {
          name = "restic-ignore-file";
          text = builtins.concatStringsSep "\n" cfg.backup-paths-exclude;
        };
      in
      {

        # TODO add contabo
        # s3-offsite = {
        #   paths = [ "/home/pinpox/Notes/" ];
        #   repository = "s3:https://vpn.s3.pablo.tools/restic";
        #   environmentFile = "${config.lollypops.secrets.files."restic/credentials".path}";
        #   passwordFile = "${config.lollypops.secrets.files."restic/repo-pw".path}";
        #   backupCleanupCommand = script-post;
        # };

        s3-onsite = {
          paths = cfg.backup-paths-onsite;
          repository = "s3:https://vpn.s3.pablo.tools/restic";
          environmentFile = "${config.lollypops.secrets.files."restic/credentials".path}";
          passwordFile = "${config.lollypops.secrets.files."restic/repo-pw".path}";
          backupCleanupCommand = script-post;

          extraBackupArgs = [
            "--exclude-file=${restic-ignore-file}"
            "--one-file-system"

            # TODO remove these after testing
            # "--dry-run"
            "-vv"
          ];
        };
      };
  };
}
