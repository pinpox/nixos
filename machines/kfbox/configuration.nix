{ self, config, s3photoalbum, go-karma-bot, retiolum, mc3000, ... }: {

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


  # often hangs
  systemd.services.systemd-networkd-wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;



  lollypops.deployment.host = "46.38.242.17";

  services.logind.extraConfig = ''
    RuntimeDirectorySize=20G
  '';

  imports = [
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    #retiolum.nixosModules.ca
    s3photoalbum.nixosModules.s3photoalbum
    s3photoalbum.nixosModules.s3photoalbum-thumbnailer
    go-karma-bot.nixosModules.go-karma-bot
  ];

  # Karmabot for IRC channel
  lollypops.secrets.files."go-karma-bot/envfile" = { };
  services.go-karma-bot.environmentFile = [ config.lollypops.secrets.files."go-karma-bot/envfile".path ];
  services.go-karma-bot.enable = true;

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
      # mattermost.enable = true;
      miniflux.enable = true;
      thelounge.enable = true;
      kf-homepage.enable = true;
    };

    metrics.node.enable = true;
  };

  programs.ssh.startAgent = false;

  services.s3photoalbum.enable = true;
  services.s3photoalbum-thumbnailer.enable = true;

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
    # Allow port for photoalbum on wg interface
    interfaces.wg0.allowedTCPPorts = [ 7788 ];
  };

  lollypops.secrets.files."gitea/mailer-pw" = {
    owner = "gitea";
    path = "/var/lib/gitea/mailer-pw";
  };

  services.gitea = {
    enable = true;
    domain = "git.0cx.de";
    rootUrl = "https://git.0cx.de";
    httpPort = 3333;
    httpAddress = "127.0.0.1";

    mailerPasswordFile = "${config.lollypops.secrets.files."gitea/mailer-pw".path}";

    settings = {
      mailer = {
        DISABLE_REGISTRATION = true;
        ENABLED = true;
        FROM = "git@0cx.de";
        MAILER_TYPE = "smtp";
        IS_TLS_ENABLED = false;
        USER = "mail@0cx.de";
        HOST = "r19.hallo.cloud:587";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";

    # commonHttpConfig = ''
    #   server_names_hash_bucket_size 128;
    # '';

    virtualHosts = {

      "megaclan3000.de" = {
        forceSSL = true;
        enableACME = true;
        root = mc3000.packages.x86_64-linux.mc3000;
      };


      "git.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:3333"; };
      };

      # The Lounge IRC
      "irc.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9090"; };
      };

      # "chat.0cx.de" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = self.inputs.nixpkgs.legacyPackages.x86_64-linux.cinny;
      # };

      # Pads
      "pads.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        locations."/socket.io/ " = {
          proxyPass = "http://127.0.0.1:3000";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
          '';
        };
      };

      # # Mattermost
      # "mm.0cx.de" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   locations."/" = {
      #     proxyPass = "http://127.0.0.1:8065";
      #     proxyWebsockets = true;

      #     extraConfig = ''
      #       proxy_pass_request_headers on;
      #       add_header Access-Control-Allow-Origin *;
      #       client_max_body_size 50M;
      #       proxy_set_header Connection "";
      #       proxy_set_header Host $host;
      #       proxy_set_header X-Real-IP $remote_addr;
      #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      #       proxy_set_header X-Forwarded-Proto $scheme;
      #       proxy_set_header X-Frame-Options SAMEORIGIN;
      #       proxy_buffers 256 16k;
      #       proxy_buffer_size 16k;
      #       proxy_read_timeout 600s;
      #       proxy_cache_revalidate on;
      #       proxy_cache_min_uses 2;
      #       proxy_cache_use_stale timeout;
      #       proxy_cache_lock on;
      #     '';
      #   };

      #   locations."~ /api/v[0-9]+/(users/)?websocket$" = {
      #     extraConfig = ''
      #       proxy_pass_request_headers on;
      #       add_header Access-Control-Allow-Origin *;
      #       proxy_set_header Upgrade $http_upgrade;
      #       proxy_set_header Connection "upgrade";
      #       client_max_body_size 50M;
      #       proxy_set_header Host $host;
      #       proxy_set_header X-Real-IP $remote_addr;
      #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      #       proxy_set_header X-Forwarded-Proto $scheme;
      #       proxy_set_header X-Frame-Options SAMEORIGIN;
      #       proxy_buffers 256 16k;
      #       proxy_buffer_size 16k;
      #       client_body_timeout 60;
      #       send_timeout 300;
      #       lingering_timeout 5;
      #       proxy_connect_timeout 90;
      #       proxy_send_timeout 300;
      #       proxy_read_timeout 90s;
      #     '';

      #     proxyPass = "http://127.0.0.1:8065";
      #     proxyWebsockets = true;
      #   };
      # };
    };
  };
}
