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

  # Add rclone to system packages for mount helper support
  environment.systemPackages = [ pkgs.rclone ];

  # Hetzner Storage Box mount with rclone - using proper mount helper
  # Mounts on first access via automount, unmounts after 10min idle
  fileSystems."/mnt/storagebox" = {
    device = ":sftp:";
    fsType = "rclone";
    options = [
      "rw"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=30s"
      "args2env"
      "vfs_cache_mode=full"
      "cache_dir=/var/cache/rclone-storagebox"
      "checkers=8"
      "umask=002"
      "allow_other"
      "sftp_host=u515095.your-storagebox.de"
      "sftp_user=u515095"
      "sftp_port=23"
      "sftp_key_file=${config.clan.core.vars.generators."storagebox-ssh".files."ssh-private-key".path}"
      "vfs_cache_max_size=10G"
      "vfs_cache_max_age=168h"
      "vfs_read_ahead=128M"
      "buffer_size=64M"
      "dir_cache_time=5m"
      "log_level=INFO"
      "log_systemd=true"
    ];
  };
}
