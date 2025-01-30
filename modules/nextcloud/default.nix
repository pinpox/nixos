{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.nextcloud;
in
{

  options.pinpox.services.nextcloud = {
    enable = mkEnableOption "Nextcloud";
  };

  config = mkIf cfg.enable {

    # Backup
    pinpox.services.restic-client.backup-paths-onsite = [ "/var/lib/nextcloud" ];

    pinpox.services.restic-client.backup-paths-offsite = [
      # TODO Plan on how to backup nextcloud data
      # "${config.services.nextcloud.home}/data"
      "${config.services.nextcloud.home}/config"
      # "${config.services.nextcloud.home}/store-apps"
    ];

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
      caching.apcu = true;
      caching.redis = true;
      configureRedis = true;

      phpOptions."opcache.interned_strings_buffer" = "64";
      # opcache.memory_consumption=256
      # opcache.interned_strings_buffer=64
      # opcache.max_accelerated_files=100000

      settings = {
        maintenance_window_start = "4";

        trusted_proxies = [
          "192.168.7.1"
          "94.16.108.229"
        ];

        trusted_domains = [ "birne.wireguard" ];
        default_phone_region = "DE";

        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
          "OC\\Preview\\Movie"
        ];
      };

      enable = true;

      # Pin Nextcloud major version.
      # Refer to upstream docs for updating major versions
      package = pkgs.nextcloud30;

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
      };

      nginx.recommendedHttpHeaders = true;
    };

    environment.systemPackages = with pkgs; [
      exiftool
      ffmpeg
    ];

    # To run nginx alongside caddy for nextcloud only
    services.nginx.enable = false;
    # services.nginx.virtualHosts."files.pablo.tools".listen = [{ addr = "0.0.0.0"; port = 8080; }];

    # reverse_proxy http://127.0.0.1:8080
    services.caddy.virtualHosts = {

      "files.pablo.tools".extraConfig = ''

        header {
            Strict-Transport-Security max-age=31536000;
        }

        redir /.well-known/carddav /remote.php/dav/ 301
        redir /.well-known/caldav /remote.php/dav/ 301

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

    # Database configuration
    services.postgresql = {
      enable = true;
    };

    # Ensure that postgres is running *before* running the setup
    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };
}
