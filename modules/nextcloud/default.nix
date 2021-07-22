{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.nextcloud;

in {

  options.pinpox.services.nextcloud = { enable = mkEnableOption "Nextcloud"; };

  config = mkIf cfg.enable {

    services.nextcloud = {
      enable = true;

      # Pin Nextcloud major version.
      # Refer to upstream docs for updating major versions
      package = pkgs.nextcloud22;

      # Use HTTPS for links
      https = true;
      # overwriteProtocol = "https";
      hostName = "files.pablo.tools";

      # Auto-update Nextcloud Apps
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";

      # phpExtraExtensions = [];
      home = "/var/lib/nextcloud";

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
        trustedProxies = [ "192.168.7.1" "94.16.114.42" "birne.wireguard" ];
      };
    };

    # Allow incoming traffic on the VPN interface
    networking.firewall = { interfaces.wg0.allowedTCPPorts = [ 9876 ]; };

    # SSL is handled by the world-facing reverse proxy on porree, nextcloud
    # listens only on the VPN interface with HTTP
    services.nginx.virtualHosts = {
      "files.pablo.tools" = {
        listen = [{
          addr = "192.168.7.4";
          port = 9876;
        }];
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

    # TODO Backup
  };
}
