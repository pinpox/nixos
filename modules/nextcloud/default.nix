{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.nextcloud;

  # Pin Nextcloud major version.
  # Refer to upstream docs for updating major versions
  package = pkgs.nextcloud34;

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

    services.postgresql.package = pkgs.postgresql_17;

    clan.core.vars.generators."nextcloud" = {

      files.admin-pass-file = {
        owner = "nextcloud";
        # path = "/var/lib/nextcloud/admin-pass";
      };

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];

      script = ''
        mkdir -p $out
        xkcdpass > $out/admin-pass-file
      '';
    };

    # SMTP against our Stalwart instance. Both the address and the app password
    # live here: secretFile is array_replace_recursive'd over config.php LAST
    # (nixpkgs nextcloud.nix:312), so any config key supplied here wins and
    # never enters the Nix store. Only mail_smtppassword may not ALSO appear in
    # `settings` - that combination trips an assertion.
    clan.core.vars.generators."nextcloud-smtp" = {
      files.smtp-secret.owner = "nextcloud";
      prompts.address = {
        type = "line";
        persist = true;
        description = "Mail address Nextcloud authenticates and sends as (e.g. nextcloud@pinpox.com)";
      };
      prompts.smtp-password = {
        type = "hidden";
        persist = true;
        description = "Mail password for that address";
      };

      runtimeInputs = with pkgs; [
        coreutils
        jq
      ];

      script = ''
        mkdir -p $out
        addr="$(cat "$prompts/address")"
        jq -n --arg pw "$(cat "$prompts/smtp-password")" \
              --arg addr "$addr" \
              --arg local "''${addr%@*}" \
              --arg domain "''${addr#*@}" \
          '{mail_smtppassword: $pw, mail_smtpname: $addr, mail_from_address: $local, mail_domain: $domain}' \
          > $out/smtp-secret
      '';
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

      secretFile = config.clan.core.vars.generators."nextcloud-smtp".files."smtp-secret".path;

      settings = {
        # Implicit TLS on 465. "ssl" is the ONLY value that means that: the
        # option is enum [ "" "ssl" ] and "" connects in cleartext, which just
        # hangs against a TLS-only listener. mail_smtpauthtype is gone - it is
        # dead since the Swiftmailer -> Symfony Mailer move; the mechanism is
        # negotiated from the server's AUTH line. mail_smtpname/from_address/
        # domain come from the secret file above.
        mail_smtpmode = "smtp";
        mail_smtphost = "mail.pinpox.com";
        mail_smtpport = 465;
        mail_smtpsecure = "ssl";
        mail_smtpauth = true;

        maintenance_window_start = "4";

        trusted_proxies = [
          (builtins.readFile (
            config.clan.core.settings.directory + "/vars/per-machine/porree/wireguard-wg-clan-ip/ipv4/value"
          ))
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

      inherit package;

      # Use HTTPS for links
      https = true;
      # overwriteProtocol = "https";
      hostName = "files.pablo.tools";

      # Disable adding apps from the app store, apps are only configured
      # declaratively via nix
      appstoreEnable = false;
      extraApps = {
        inherit (package.packages.apps)
          mail
          calendar
          contacts
          memories

          previewgenerator
          # maps
          twofactor_webauthn
          # recognize  # works but pulls in ~100MiB libtensorflow
          music
          # phonetrack
          ;
      };

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
        adminpassFile = "${config.clan.core.vars.generators."nextcloud".files."admin-pass-file".path}";
      };

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
        encode zstd gzip

        root * ${config.services.nginx.virtualHosts."files.pablo.tools".root}
        root /nix-apps/* ${config.services.nginx.virtualHosts."files.pablo.tools".root}

        redir /.well-known/carddav /remote.php/dav 301
        redir /.well-known/caldav /remote.php/dav 301
        redir /.well-known/* /index.php{uri} 301
        redir /remote/* /remote.php{uri} 301

        header {
          Strict-Transport-Security max-age=31536000
          Permissions-Policy interest-cohort=()
          X-Content-Type-Options nosniff
          X-Frame-Options SAMEORIGIN
          Referrer-Policy strict-origin-when-cross-origin
          X-XSS-Protection "1; mode=block"
          X-Permitted-Cross-Domain-Policies none
          X-Robots-Tag "noindex, nofollow"
          -X-Powered-By
        }

        php_fastcgi unix//run/phpfpm/nextcloud.sock {
          root ${config.services.nginx.virtualHosts."files.pablo.tools".root}
          env front_controller_active true
          env modHeadersAvailable true
        }

        @forbidden {
          path /build/* /tests/* /config/* /lib/* /3rdparty/* /templates/* /data/*
          path /.* /autotest* /occ* /issue* /indie* /db_* /console*
          not path /.well-known/*
        }
        error @forbidden 404

        @immutable {
          path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
          query v=*
        }
        header @immutable Cache-Control "max-age=15778463, immutable"

        @static {
          path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
          not query v=*
        }
        header @static Cache-Control "max-age=15778463"

        @woff2 path *.woff2
        header @woff2 Cache-Control "max-age=604800"

        file_server
      '';
    };

    # Fix for memories
    # https://memories.gallery/troubleshooting/#trigger-compatibility-mode
    systemd.services.nextcloud-cron = {
      path = [ pkgs.perl ];
    };

    # Database configuration
    services.postgresql.enable = true;

    # Ensure that postgres is running *before* running the setup
    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };
}
