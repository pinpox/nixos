{ config, lib, aoe-taunt-discord-bot, go-karma-bot, retiolum, mc3000, vpub-plus-plus, ... }: {

  networking.interfaces.ens3 = {
    ipv6.addresses = [{
      address = "2a03:4000:7:4e0::";
      prefixLength = 64;
    }];
  };

  networking.retiolum = {
    ipv4 = "10.243.100.102";
    ipv6 = "42:0:3c46:3ae6:90a8:b220:e772:8a5c";
  };

  lollypops.secrets.files = {
    "retiolum/rsa_priv" = { };
    "retiolum/ed25519_priv" = { };
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "${config.lollypops.secrets.files."retiolum/rsa_priv".path}";
    ed25519PrivateKeyFile = "${config.lollypops.secrets.files."retiolum/ed25519_priv".path}";
  };


  lollypops.deployment.ssh.host = "46.38.242.17";

  services.logind.extraConfig = ''
    RuntimeDirectorySize=20G
  '';

  imports = [
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    #retiolum.nixosModules.ca
    go-karma-bot.nixosModules.go-karma-bot
    aoe-taunt-discord-bot.nixosModules.aoe-taunt-discord-bot
    vpub-plus-plus.nixosModules.vpub-plus-plus
  ];


  # Often hangs
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # Karmabot for IRC channel
  lollypops.secrets.files."go-karma-bot/envfile" = { };
  services.go-karma-bot.environmentFile = config.lollypops.secrets.files."go-karma-bot/envfile".path;
  services.go-karma-bot.enable = true;

  # Discord AoE2 taunt bot
  lollypops.secrets.files."aoe-taunt-discord-bot/discord_token" = { };
  services.aoe-taunt-discord-bot.discordTokenFile = config.lollypops.secrets.files."aoe-taunt-discord-bot/discord_token".path;
  services.aoe-taunt-discord-bot.enable = true;

  lollypops.secrets.files."transfer-sh/envfile" = { };
  services.transfer-sh = {
    enable = true;
    LISTENER = 6767;
    environmentFile = config.lollypops.secrets.files."transfer-sh/envfile".path;
    provider = "s3";

    BUCKET = "transfer-0cx";
    S3_ENDPOINT = "https://s3.lounge.rocks";
    S3_PATH_STYLE = true;
    S3_REGION = "eu-central-1";

    # HTTP_AUTH_PASS and HTTP_AUTH_USER set in envfile and in ~/.netrc
  };

  pinpox = {

    server = {
      enable = true;
      hostname = "kfbox";
      stateVersion = "22.05";
    };

    wg-client = {
      enable = true;
      clientIp = "192.168.7.5";
    };

    services = {
      borg-backup.enable = true;
      hedgedoc.enable = true;
      miniflux.enable = true;
      thelounge.enable = true;
      kf-homepage.enable = true;
    };

    metrics.node.enable = true;
  };

  programs.ssh.startAgent = false;
  services.qemuGuest.enable = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/tmp" = {
    fsType = "tmpfs";
    device = "tmpfs";
    options = [ "nosuid" "nodev" "relatime" "size=14G" ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  # Block anything that is not HTTP(s) or SSH.
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 80 443 22 ];
  };

  lollypops.secrets.files."gitea/mailer-pw" = {
    owner = "gitea";
    path = "/var/lib/gitea/mailer-pw";
  };

  # TODO PUT into module

  services.gitea = {

    enable = true;
    mailerPasswordFile = "${config.lollypops.secrets.files."gitea/mailer-pw".path}";

    settings = {
      server = {
        ROOT_URL = "https://git.0cx.de";
        HTTP_PORT = 3333;
        HTTP_ADDR = "127.0.0.1";
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
        DOMAIN = "git.0cx.de";
      };

      mailer = {
        ENABLED = true;
        FROM = "git@0cx.de";
        MAILER_TYPE = "smtp";
        IS_TLS_ENABLED = false;
        USER = "mail@0cx.de";
        HOST = "r19.hallo.cloud:587";

      };
      markdown.ENABLE_MATH = true;
    };
  };


  lollypops.secrets.files = {
    "dex/envfile" = { };
  };

  systemd.services.dex.serviceConfig.StateDirectory = "dex";

  services.dex = {
    enable = true;
    environmentFile = config.lollypops.secrets.files."dex/envfile".path;
    settings = {

      # External url
      issuer = "https://login.0cx.de";
      storage = {
        type = "sqlite3";
        config.file = "/var/lib/dex/dex.db";
      };

      web.http = "127.0.0.1:5556";

      # enablePasswordDB = true;
      # telemetry.http = "127.0.0.1:5558";

      logger = {
        #   level: "debug"
        format = "json"; # can also be "text"
      };

      frontend = {
        issuer = "https://login.0cx.de";
        logoURL = "https://0cx.de/dance.gif";
        theme = "dark";
      };

      connectors = [
        {
          type = "gitea";
          id = "gitea";
          name = "Gitea";
          config = {
            # Credentials can be string literals or pulled from the environment.
            clientID = "$GITEA_CLIENT_ID";
            clientSecret = "$GITEA_CLIENT_SECRET";
            redirectURI = "https://login.0cx.de/callback";
            baseURL = config.services.gitea.settings.server.ROOT_URL;
          };
        }
        {
          type = "github";
          id = "github";
          name = "GitHub";
          config = {
            clientID = "$GITHUB_CLIENT_ID";
            clientSecret = "$GITHUB_CLIENT_SECRET";
            redirectURI = "https://login.0cx.de/callback";
            orgs = [
              { name = "lounge-rocks"; }
              # {name = "krosse-flagge";}
            ];
          };
        }
      ];

      staticClients = [
        {
          id = "forum-app";
          name = "forum-app";
          redirectURIs = [ "http://localhost:8000/authenticate" ];
          secretEnv = "CLIENT_SECRET_RUST_FORUM";
        }
        {
          id = "hedgedoc";
          name = "hedgedoc";
          redirectURIs = [ "https://pads.0cx.de/auth/oauth2/callback" ];
          secretEnv = "CLIENT_SECRET_HEDGEDOC";
        }
      ];
    };
  };
  services.caddy = {
    enable = true;

    virtualHosts = {

      "megaclan3000.de".extraConfig = ''
        root * ${mc3000.packages.x86_64-linux.mc3000}
        file_server
        encode zstd gzip
      '';

      "irc.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:9090";
      "transfer.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:6767";
      "login.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:5556";
      "git.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:3333";
      "pads.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:3000";

    };
  };
}
