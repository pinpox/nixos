{
  config,
  pkgs,
  ...
}:
{
  # SSH keypair generator for Hetzner Storage Box
  clan.core.vars.generators."storagebox-ssh" = {
    files.ssh-private-key = { };
    files.ssh-public-key.secret = false;
    runtimeInputs = with pkgs; [ openssh ];
    script = ''
      mkdir -p $out
      ssh-keygen -t ed25519 -f $out/ssh-private-key -N "" -C "kiwi-storagebox"
      mv $out/ssh-private-key.pub $out/ssh-public-key
    '';
  };

  # Hetzner Storage Box mount with rclone (stateless, no config file needed)
  systemd.services.rclone-storagebox = {
    description = "rclone mount for Hetzner Storage Box";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      RCLONE_SFTP_HOST = "u515095.your-storagebox.de";
      RCLONE_SFTP_USER = "u515095";
      RCLONE_SFTP_PORT = "23";
      RCLONE_SFTP_KEY_FILE = config.clan.core.vars.generators."storagebox-ssh".files."ssh-private-key".path;
      RCLONE_VFS_CACHE_MODE = "full";
      RCLONE_VFS_CACHE_MAX_SIZE = "10G";
      RCLONE_VFS_CACHE_MAX_AGE = "168h";
      RCLONE_VFS_READ_AHEAD = "128M";
      RCLONE_BUFFER_SIZE = "64M";
      RCLONE_DIR_CACHE_TIME = "5m";
      RCLONE_LOG_LEVEL = "INFO";
      RCLONE_LOG_SYSTEMD = "true";
    };

    serviceConfig = {
      Type = "notify";
      CacheDirectory = "rclone-storagebox";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/storagebox";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount :sftp: /mnt/storagebox \
          --cache-dir=''${CACHE_DIRECTORY} \
          --checkers=8 \
          --umask=002 \
          --allow-other
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/storagebox";
      Restart = "on-failure";
      RestartSec = "10s";
      User = "root";
      Group = "root";
      KillMode = "control-group";
      KillSignal = "SIGINT";
      TimeoutStopSec = "30s";
    };
  };
}
