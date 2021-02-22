{ config, pkgs, lib, ... }: {
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

    # Print more infomation to log and set intervals at which resumable
    # checkpoints are created
    extraCreateArgs = "--verbose --list --checkpoint-interval 600";

    # Exclude some directories from backup that contain garbage
    exclude = [
      "*.pyc"
      "*/cache2"
      "/*/.cache"
      "/*/.config/Signal"
      "/*/.config/chromium"
      "/*/.config/discord"
      "/*/.container-diff"
      "/*/.gvfs/"
      "/*/.local/share/Trash"
      "/*/.mozilla/firefox/*.default/Cache"
      "/*/.mozilla/firefox/*.default/OfflineCache"
      "/*/.npm/_cacache"
      "/*/.thumbnails"
      "/*/.ts3client"
      "/*/.vagrant.d"
      "/*/.vim"
      "/*/Cache"
      "/*/Downloads"
      "/*/Seafile"
      "/*/Projects/nixpkgs"
      "/*/VirtualBox VMs"
      "discord/Cache"
    ];

    compression = "lz4";

    # Backup will run daily
    startAt = "daily";

    # Write information for last snapshot to be retrieved by the monitoring
    # readWritePaths = [ "/var/log" ];
    # postHook = ''
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

}
