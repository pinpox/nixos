{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.pinpox.services.borg-backup;
in
{
  options.pinpox.services.borg-backup = {
    enable = mkEnableOption "daily backup with borg";
  };

  config = mkIf cfg.enable {
    # Backup with borgbackup to remote server. The connection key and repository
    # encryption passphrase is read from /secrets. This directory has to be
    # copied ther *manually* (so this config can be shared publicly)!
    services.borgbackup.jobs.box-backup = {
      # Paths to backup
      paths = [ "/home" "/root" "/var/lib" ];

      # Remote servers repository to use. Archives will be labeled with the
      # hostname and a timestamp
      # repo = "borg@birne.wireguard:.";
      repo = "borg@birne.wireguard:.";

      # Don't create repo if it does not exist. Ensures the backup fails, if for
      # some reason the backup drive is not mounted or the path has changed.
      doInit = false;

      # Encryption and connection keys are read from /secrets
      encryption = {
        mode = "repokey";
        passCommand = "cat /var/src/secrets/borg/passphrase";
      };

      environment.BORG_RSH = "ssh -i /var/src/secrets/ssh/borg/private";

      environment.BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";

      # Print more infomation to log and set intervals at which resumable
      # checkpoints are created
      extraCreateArgs = "--verbose --list --checkpoint-interval 600";

      # Exclude some directories from backup that contain garbage
      exclude = [
        "*.pyc"
        "*/cache2"
        "/*/.cache"
        "/*/.go/pkg"
        "/*/.config/Signal"
        "/*/.local/share/Steam"
        "/*/.config/chromium"
        "/*/.rustup"
        "/*/.config/discord"
        "/*/.container-diff"
        "/*/.gvfs/"
        "/*/.local/share/Trash"
        "/*/.mozilla/firefox"
        "/*/.npm/_cacache"
        "/*/.thumbnails"
        "/*/.ts3client"
        "/*/.vagrant.d"
        "/*/.vim"
        "/*/Cache"
        "/*/Downloads"
        "/*/Seafile"
        "/*/.nextcloud"
        "/*/code/nixpkgs"
        "/*/code/vaultwarden"
        "/*/code/github.com/pinpox/nixpkgs"
        "/*/code/github.com/NixOS/nixpkgs"
        "/*/VirtualBox VMs"
        "discord/Cache"
      ];

      compression = "lz4";

      # Backup will run daily
      startAt = "daily";

      # Write information for last snapshot to be retrieved by the monitoring
      # readWritePaths = [ "/dev/stderr" "/proc/self/fd/2" ];

      # postCreate = ''
      #   ${pkgs.curl}/bin/curl -X POST \
      #     -d"<p>💾 <strong><font color='#0000ff'>BACKUP</font> </strong><code>[${config.networking.hostName}]</code> >> Created successfully</br><blockquote>$archiveName $exitStatus</blockquote>" \
      #     https://vpn.notify.pablo.tools/plain
      #   ${pkgs.nur.repos.mic92.irc-announce}/bin/irc-announce irc.hackint.org 6697 backup-reporter '#lounge-rocks-log' 1 "💾 [${config.networking.hostName}] Backup created: $archiveName"
      # '';
      postHook = ''
        if [ $exitStatus -ne 0 ]; then
          ${pkgs.curl}/bin/curl -X POST \
            -d"<p>💾 <strong><font color='#ff0000'>BACKUP</font> </strong><code>[${config.networking.hostName}]</code> >> FAILED!</br>\
            <blockquote>Archive: $archiveName</br>Status: $exitStatus</blockquote>" \
            https://vpn.notify.pablo.tools/plain
        else
          ${pkgs.curl}/bin/curl -X POST \
            -d"<p>💾 <strong><font color='#0000ff'>BACKUP</font> </strong><code>[${config.networking.hostName}]</code> >> Created successfully</br>\
            <blockquote>Archive: $archiveName</br>Status: $exitStatus</blockquote>" \
            https://vpn.notify.pablo.tools/plain
        fi
      '';
      #   borg info --json --last 1 borg@birne.wireguard:. > /var/log/borgbackup-last-info
      #   echo $exitStatus > /var/log/borgbackup-last-status
      #   '';

      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 7;
        weekly = 4;
        monthly = 3;
      };
    };
  };
}
