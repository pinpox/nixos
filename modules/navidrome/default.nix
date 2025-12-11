{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.navidrome;
in
{

  options.pinpox.services.navidrome = {
    enable = mkEnableOption "navidrome music player";

    host = mkOption {
      type = types.str;
      default = "music.0cx.de";
      description = "Host serving the navidrome";
      example = "party.0cx.de";
    };

  };

  config = mkIf cfg.enable {

    # Reverse proxy
    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig =
        "reverse_proxy 127.0.0.1:${toString config.services.navidrome.settings.Port}";
    };

    # Mount storagebox
    pinpox.defaults.storagebox = {
      enable = true;
      mountOnAccess = false;
    };

    # Add navidrome user to storage-users group for access to storagebox
    users.users.navidrome.extraGroups = [ "storage-users" ];

    # Set up navidrome
    services.navidrome = {
      enable = true;
      settings.Port = 4533;
      settings.Address = "127.0.0.1";
      settings.MusicFolder = "${config.pinpox.defaults.storagebox.mountPoint}/music";
      # openFirewall
      # environmentFile
    };

    # Ensure storagebox is mounted before navidrome starts
    systemd.services.navidrome = {
      requires = [ "mnt-storagebox.mount" ];
      after = [ "mnt-storagebox.mount" ];
    };
  };
}
