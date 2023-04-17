{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.nextcloud;

in
{

  options.pinpox.services.nextcloud = { enable = mkEnableOption "Nextcloud"; };

  config = mkIf cfg.enable {

    services.postgresql.package = pkgs.postgresql_13;

    lollypops.secrets.files = {
      "nextcloud/admin-pass" = {
        # name = "nextcloud-admin-pass";
        path = "/var/lib/nextcloud/admin-pass";
        owner = "nextcloud";
      };
    };


    services.phpfpm.pools.nextcloud.settings = {
      "listen.owner" = config.services.caddy.user;
      "listen.group" = config.services.caddy.group;
    };



    services.nextcloud = {


      enable = true;

      # Disable broken RC4 cipher which is only necessary if you're using
      # Nextcloud's server-side encryption.
      # https://github.com/NixOS/nixpkgs/pull/198470
      enableBrokenCiphersForSSE = false;

      # Pin Nextcloud major version.
      # Refer to upstream docs for updating major versions
      package = pkgs.nextcloud26;

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
        adminpassFile = "${config.lollypops.secrets.files."nextcloud/admin-pass".path}";

        defaultPhoneRegion = "DE";
        extraTrustedDomains = [ "birne.wireguard" ];
        trustedProxies = [ "192.168.7.1" "94.16.108.229" "birne.wireguard" ];
      };

      nginx.recommendedHttpHeaders = true;


    };



    # redis.servers.nextcloud = {
    #   enable = true;
    #   user = "nextcloud";
    #   port = 0;
    # };

    # To run nginx alongside caddy for nextcloud only
    services.nginx.enable = false;
    # services.nginx.virtualHosts."files.pablo.tools".listen = [{ addr = "0.0.0.0"; port = 8080; }];

    # reverse_proxy http://127.0.0.1:8080
    services.caddy.virtualHosts = {
      "files.pablo.tools".extraConfig = ''

        redir /.well-known/carddav /remote.php/dav 301
        redir /.well-known/caldav /remote.php/dav 301

        @forbidden {
            path /.htaccess
            path /data/*
            path /config/*
            path /db_structure
            path /.xml
            path /README
            path /3rdparty/*
            path /lib/*
            path /templates/*
            path /occ
            path /console.php
        }
        respond @forbidden 404

        root * ${config.services.nextcloud.package}
        file_server
        php_fastcgi unix//run/phpfpm/nextcloud.sock
      '';
    };


    # reverse_proxy 127.0.0.2:9876
    # services.caddy.virtualHosts."files.pablo.tools".extraConfig = ''
    #   root * ${pkgs.nextcloud26}
    #   file_server
    # '';

    # Reverse proxy
    # services.nginx.virtualHosts = {
    #   "files.pablo.tools" = {
    #     forceSSL = true;
    #     enableACME = true;
    #     locations."/" = {
    #       proxyPass = "http://127.0.0.2:9876";
    #       proxyWebsockets = true;
    #     };
    #   };
    # };

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
