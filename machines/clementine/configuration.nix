{
  config,
  mc3000,
  trippy-track,
  pinpox-utils,
  ...
}:
{
  imports = [ trippy-track.nixosModules.default ];

  clan.core.networking.targetHost = "152.53.139.179";
  networking.hostName = "clementine";

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a0a:4cc0:c0:f339::1";
        prefixLength = 64;
      }
    ];
  };

  pinpox.services.twitch-first.enable = true;

  # Mail: Stalwart 0.16 + Bulwark webmail (migrated from kfbox). pinpox.com is
  # the primary domain (mail host mail.pinpox.com, webmail webmail.pinpox.com,
  # mailbox pinpox@pinpox.com); megaclan3000.de is a secondary/alias domain.
  # Both catch-all to pinpox, who owns both addresses (send-as). lislon later.
  # The module opens its own mail ports (25/465/993) and adds the Caddy vhosts.
  pinpox.services.mail = {
    enable = true;
    primaryDomain = "pinpox.com";
    domains = {
      "pinpox.com".catchAll = "pinpox@pinpox.com";
      "megaclan3000.de".catchAll = "pinpox@megaclan3000.de";
    };
    accounts.pinpox = {
      domain = "pinpox.com";
      aliasDomains = [ "megaclan3000.de" ];
    };
  };

  clan.core.vars.generators."trippy-track" = pinpox-utils.mkEnvGenerator [
    "OIDC_ISSUER_URL"
    "OIDC_CLIENT_ID"
    "OIDC_CLIENT_SECRET"
    "OIDC_REDIRECT_URL"

    "VAPID_PRIVATE_KEY"
    "VAPID_PUBLIC_KEY"
    "VAPID_CONTACT"
  ];

  services.trippy-track = {
    enable = true;
    port = 8090;
    environmentFile = config.clan.core.vars.generators."trippy-track".files."envfile".path;
  };

  services.qemuGuest.enable = true;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      80
      443
      22
    ];
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "megaclan3000.de".extraConfig = ''
        handle /.well-known/caldav {
          redir https://mail.pinpox.com/dav/cal 301
        }
        handle /.well-known/carddav {
          redir https://mail.pinpox.com/dav/card 301
        }
        handle /.well-known/autoconfig/* {
          redir https://autoconfig.megaclan3000.de{uri} 301
        }

        handle {
          root * ${mc3000.packages.x86_64-linux.mc3000}
          file_server
          encode zstd gzip
        }
      '';
      "travel.pinpox.com".extraConfig = ''
        reverse_proxy localhost:8090
      '';
    };
  };
}
