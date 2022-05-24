{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.nextcloud;

in
{

  options.pinpox.services.nextcloud = { enable = mkEnableOption "Nextcloud"; };

  config = mkIf cfg.enable {

    services.nextcloud = {
      enable = true;

      # Pin Nextcloud major version.
      # Refer to upstream docs for updating major versions
      package = pkgs.nextcloud23;

      # Use HTTPS for links
      https = true;
      # overwriteProtocol = "https";
      hostName = "files.pablo.tools";

      # Auto-update Nextcloud Apps
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";

      # phpExtraExtensions = [];
      home = "/var/lib/nextcloud";

      poolSettings = {
        pm = "dynamic";
        "pm.max_children" = "160";
        "pm.max_requests" = "700";
        "pm.max_spare_servers" = "120";
        "pm.min_spare_servers" = "40";
        "pm.start_servers" = "40";
      };

      config = {

        # Database
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";

        # Admin user
        adminuser = "pinpox";
        adminpassFile = "/run/keys/nextcloud-admin-pass";

        defaultPhoneRegion = "DE";
        extraTrustedDomains = [ "birne.wireguard" ];
        trustedProxies = [ "192.168.7.1" "94.16.108.229" "birne.wireguard" ];
      };
    };

    # Reverse proxy
    services.nginx.virtualHosts = {
      "files.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.2:9876";
          proxyWebsockets = true;
        };
      };
    };

    # Deploy admin account credentials
    users.users.nextcloud = { extraGroups = [ "keys" ]; };
    krops.secrets.files = {
      nextcloud-admin-pass = {
        owner = "nextcloud";
        source-path = "/var/src/secrets/nextcloud/admin-pass";
      };
    };

    # Database configuration
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }];
    };

    # Ensure that postgres is running *before* running the setup
    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };

    # Backup
    services.borgbackup.jobs.box-backup.paths = [ "/var/lib/nextcloud" ];
  };
}
