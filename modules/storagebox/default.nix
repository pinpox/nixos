{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.storagebox;
in
{

  options.pinpox.defaults.storagebox = {

    enable = mkEnableOption "storagebox access";

    mountOnAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to mount on access, instead of permanently";
      example = true;
    };
    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/storagebox";
      description = "Where to mount the storage";
      example = "/mnt/music";
    };
  };

  config = mkIf cfg.enable {

    # Hard-code an unsused gid for the group
    users.groups.storage-users.gid = 982;

    # SSH keypair generator for Hetzner Storage Box
    clan.core.vars.generators."storagebox-ssh" = {
      share = true;
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
    # Create cache directory for rclone
    systemd.tmpfiles.rules = [
      "d /var/cache/rclone-storagebox 0750 root storage-users -"
    ];

    fileSystems."${cfg.mountPoint}" = {
      device = ":sftp:";
      fsType = "rclone";
      options = [
        "rw"
        "nofail"
        "_netdev"
        "x-systemd.mount-timeout=120s"
        "args2env"
        "config=/dev/null"
        "vfs_cache_mode=full"
        "cache_dir=/var/cache/rclone-storagebox"
        "checkers=8"
        "gid=${toString config.users.groups.storage-users.gid}"
        "umask=007"
        "allow_other"
        "allow_non_empty"
        "links"
        "sftp_host=u515095.your-storagebox.de"
        "sftp_user=u515095"
        "sftp_port=23"
        "sftp_key_file=${config.clan.core.vars.generators."storagebox-ssh".files."ssh-private-key".path}"
        "vfs_cache_max_size=2G"
        "vfs_cache_max_age=5m"
        "vfs_read_ahead=128M"
        "buffer_size=64M"
        "dir_cache_time=30s"
        "log_level=INFO"
        "log_systemd=true"
      ]
      ++ optionals cfg.mountOnAccess [
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
      ];
    };
  };
}
