{
  lib,
  pkgs,
  config,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.restic-client;
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

    backup-paths-offsite = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/Notes" ];
      description = "Paths to backup to offsite storage";
    };

    backup-paths-exclude = mkOption {
      type = types.listOf types.str;
      default = [
        "*.pyc"
        "*/.BurpSuite"
        "*/.arduino15/packages"
        "*/.cache"
        "*/.cargo"
        "*/.coc"
        "*/.config/Nextcloud/logs"
        "*/.config/Signal"
        "*/.config/chromium"
        "*/.config/discord"
        "*/.config/retroarch"
        "*/.container-diff"
        "*/.go/pkg"
        "*/.gvfs/"
        "*/.local/share/Steam"
        "*/.local/share/Trash"
        "*/.local/share/tor-browser"
        "*/.local/share/typeracer"
        "*/.local/share/virtualenv"
        "*/.local/state/NvChad/"
        "*/.mozilla/firefox"
        "*/.nextcloud"
        "*/.npm"
        "*/.npm/_cacache"
        "*/.platformio"
        "*/.rustup"
        "*/.thumbnails"
        "*/.ts3client"
        "*/.vagrant.d"
        "*/.vim"
        "*/.vimtemp"
        "*/Cache"
        "*/Downloads"
        "*/Seafile"
        "*/VirtualBox VMs"
        "*/cache2"
        "*/code"
        "/var/lib/docker"
        "discord/Cache"
        "tags"
      ];
      example = [ "/home/pinpox/cache" ];
      description = "Paths to exclude from backup";
    };
  };

  config =
    let
      s3-generator =
        (pinpox-utils.mkEnvGenerator [
          "AWS_ACCESS_KEY_ID"
          "AWS_SECRET_ACCESS_KEY"
          "NTFY_USER"
          "NTFY_PASS"
        ])
        // {
          share = true;
        };
    in

    mkIf cfg.enable {

      clan.core.vars.generators."restic-credentials" = s3-generator;
      clan.core.vars.generators."restic-credentials-backblaze" = s3-generator;

      clan.core.vars.generators."restic" = {
        files.repo-pw = { };
        runtimeInputs = with pkgs; [
          coreutils
          xkcdpass
        ];
        script = ''
          mkdir -p $out
          xkcdpass -d- > $out/repo-pw
        '';
      };

      clan.core.vars.generators."restic-offsite" = {
        prompts.repo-pw.persist = true;
        share = true;
      };

      services.restic.backups =
        let
          script-post = host: site: ''
            if [ $EXIT_STATUS -ne 0 ]; then
              ${pkgs.curl}/bin/curl -u $NTFY_USER:$NTFY_PASS \
              -H 'Title: Backup (${site}) on ${host} failed!' \
              -H 'Tags: backup,restic,${host},${site}' \
              -d "Restic (${site}) backup error on ${host}!" 'https://push.pablo.tools/pinpox_backups'
            else
              ${pkgs.curl}/bin/curl -u $NTFY_USER:$NTFY_PASS \
              -H 'Title: Backup (${site}) on ${host} successful!' \
              -H 'Tags: backup,restic,${host},${site}' \
              -d "Restic (${site}) backup success on ${host}!" 'https://push.pablo.tools/pinpox_backups'
            fi
          '';

          restic-ignore-file = pkgs.writeTextFile {
            name = "restic-ignore-file";
            text = builtins.concatStringsSep "\n" cfg.backup-paths-exclude;
          };

          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 12"
            "--keep-yearly 75"
          ];

          extraBackupArgs = [
            "--exclude-file=${restic-ignore-file}"
            "--one-file-system"
            "-vv"
          ];

        in
        {
          s3-offsite = {
            paths = cfg.backup-paths-offsite;
            repository = "s3:https://s3.us-east-005.backblazeb2.com/pinpox-restic";
            environmentFile = "${config.clan.core.vars.generators."restic-credentials-backblaze".files."envfile".path
            }";
            passwordFile = "${config.clan.core.vars.generators."restic-offsite".files."repo-pw".path}";
            backupCleanupCommand = script-post config.networking.hostName "backblaze";
            inherit pruneOpts extraBackupArgs;
          };

          s3-onsite = {
            paths = cfg.backup-paths-onsite;
            repository = "s3:https://vpn.s3.pablo.tools/restic";
            environmentFile = "${config.clan.core.vars.generators."restic-credentials".files."envfile".path}";
            passwordFile = "${config.clan.core.vars.generators."restic".files."repo-pw".path}";
            backupCleanupCommand = script-post config.networking.hostName "NAS";
            inherit pruneOpts extraBackupArgs;
          };
        };
    };
}
