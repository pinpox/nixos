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
        # LLM weights, re-downloadable and hundreds of GB, in any folder.
        "*.gguf"
        "*.safetensors"
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
        "*/.lmstudio/models"
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
        # Raw footage and exports, hundreds of GB; too big for the backups.
        "/home/*/Videos"
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
        ])
        // {
          share = true;
        };

      backupNames = [
        "s3-offsite"
        "s3-onsite"
      ];

      # Written by ExecStartPost, which systemd only runs after every
      # ExecStart step (backup, unlock, forget --prune) exited 0. Read by the
      # textfile collector in
      # clan-service-modules/monitoring-glue/client-collectors.nix; one file
      # per backup, replaced atomically so a half-written file is never
      # scraped. Survives reboots, so an old stamp stays visible.
      textfileDir = "/var/lib/prometheus-textfile";
      successStamp = pkgs.writeShellScript "restic-backup-success-stamp" ''
        set -eu
        mkdir -p ${textfileDir}
        tmp=$(mktemp ${textfileDir}/.restic-"$1".XXXXXX)
        printf '# TYPE restic_backup_last_success_timestamp_seconds gauge\nrestic_backup_last_success_timestamp_seconds{backup="%s"} %s\n' \
          "$1" "$(date +%s)" > "$tmp"
        mv "$tmp" ${textfileDir}/restic-"$1".prom
      '';
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
            inherit pruneOpts extraBackupArgs;
          };

          s3-onsite = {
            paths = cfg.backup-paths-onsite;
            repository = "s3:https://vpn.s3.pablo.tools/restic";
            environmentFile = "${config.clan.core.vars.generators."restic-credentials".files."envfile".path}";
            passwordFile = "${config.clan.core.vars.generators."restic".files."repo-pw".path}";
            inherit pruneOpts extraBackupArgs;
          };
        };

      systemd.services = lib.genAttrs (map (n: "restic-backups-${n}") backupNames) (unit: {
        serviceConfig.ExecStartPost = "${successStamp} ${lib.removePrefix "restic-backups-" unit}";
      });
    };
}
