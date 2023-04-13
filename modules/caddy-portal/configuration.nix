{ matrix-hook, pkgs, config, retiolum, alertmanager-ntfy, ... }: {

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    alertmanager-ntfy.nixosModules.default
    retiolum.nixosModules.retiolum
    # ./retiolum.nix
  ];

  networking.interfaces.ens3 = {
    ipv6.addresses = [{
      address = "2a03:4000:51:aa3::1";
      prefixLength = 64;
    }];
  };

  lollypops.deployment.ssh.host = "94.16.108.229";


  # services.influxdb2.enable = true;
  # services.influxdb2.settings = { };

  lollypops.secrets.files = {
    "matrix-hook/envfile" = { };
    "alertmanager-ntfy/envfile" = { };
    "bitwarden_rs/envfile" = { };
    "wireguard/private" = { };
    "nginx/blog.passwd" = {
      path = "/var/www/blog.passwd";
      owner = "nginx";
    };

    "nginx/3dprint.passwd" = {
      path = "/var/www/3dprint.passwd";
      owner = "nginx";
    };
    "matrix-hook/alerts.passwd" = {
      path = "/var/lib/matrix-hook/alerts.passwd";
      owner = "nginx";
    };
  };


  networking.retiolum.ipv4 = "10.243.100.101";
  networking.retiolum.ipv6 = "42:0:3c46:b51c:b34d:b7e1:3b02:8d24";

  lollypops.secrets.files = {
    "retiolum/rsa_priv" = { };
    "retiolum/ed25519_priv" = { };
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "${config.lollypops.secrets.files."retiolum/rsa_priv".path}";
    ed25519PrivateKeyFile = "${config.lollypops.secrets.files."retiolum/ed25519_priv".path}";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gtk2";
  };

  services.qemuGuest.enable = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Block anything that is not HTTP(s) or SSH.
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 80 443 22 ];
    allowedUDPPorts = [ 51820 ];

    interfaces.wg0.allowedTCPPorts = [
      2812
      8086 # InfluxDB
    ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  programs.ssh.startAgent = false;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  services.nginx = {

    # resolver = {
    #   addresses = [
    #     "1.1.1.1"
    #   ];
    # };

    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";
    recommendedProxySettings = true;

    # Needed for vaultwarden, it seems to have trouble serving scripts for
    # the frontend without it.
    commonHttpConfig = ''
      server_names_hash_bucket_size 128;
      proxy_headers_hash_max_size 1024;
      proxy_headers_hash_bucket_size 256;
    '';

    # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
    # provided by Let's Encrypt via ACME. Generation and renewal is automatic
    # if DNS is set up correctly for the (sub-)domains.
    virtualHosts = {
      # Personal homepage and blog
      "pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/pablo-tools";
        locations."~*\.(css|gif|woff2|woff|png|jpeg)$" = {
          extraConfig = ''
            access_log off;
            expires max;
            add_header Access-Control-Allow-Origin *;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
          '';
        };
      };

      "beta.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/pablo-tools-beta";
        basicAuthFile = "${config.lollypops.secrets.files."nginx/blog.passwd".path}";
        locations."~*\.(css|gif|woff2|woff|png|jpeg)$" = {
          extraConfig = ''
            access_log off;
            expires max;
          '';
        };
      };

      # Password manager (vaultwarden) instance
      "pass.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:8222"; };
      };

      # Octoprint
      # Set /etc/hosts of client
      "vpn.octoprint.pablo.tools" = {

        listenAddresses = [ "192.168.7.1" ];

        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://192.168.2.121:5000";
        };
      };

      # Motion camera admin interface
      # Set /etc/hosts of client
      "vpn.motion.pablo.tools" = {
        listenAddresses = [ "192.168.7.1" ];
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://192.168.2.121:8082"; };
      };

      # Camera (read-only) stream
      "3dprint.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://192.168.2.121:8081"; };
        basicAuthFile = "${config.lollypops.secrets.files."nginx/3dprint.passwd".path}";
      };

      # Photo gallery
      "photos.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://192.168.7.5:7788"; };
      };

      # Graphana
      "status.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://127.0.0.1:9005";
        };
      };

      # InfluxDB
      # "vpn.influx.pablo.tools" = {
      #   listen = [{
      #     addr = "192.168.7.1";
      #     port = 443;
      #     ssl = true;
      #   }];
      #   forceSSL = true;
      #   enableACME = true;
      #   locations."/" = { proxyPass = "http://127.0.0.1:8086"; };
      # };

      # Alertmanager
      # Set /etc/hosts of client
      "vpn.alerts.pablo.tools" = {
        listen = [{
          addr = "192.168.7.1";
          port = 443;
          ssl = true;
        }];
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9093"; };
      };

      # Set /etc/hosts of client
      "vpn.prometheus.pablo.tools" = {
        listen = [{
          addr = "192.168.7.1";
          port = 443;
          ssl = true;
        }];
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9090"; };
      };

      "notify.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:11000"; };
        # Deploy htpaswd file for external alerts
        # Generate with: mkpasswd -m sha-512 (save as username:$6$E7UzqcDh3$Xi...)
        # Test with: curl -X POST -d'test' https://user:password@notify.pablo.tools/plain
        basicAuthFile = "${config.lollypops.secrets.files."matrix-hook/alerts.passwd".path}";
      };

      # Set /etc/hosts of client
      "vpn.notify.pablo.tools" = {
        listen = [{
          addr = "192.168.7.1";
          port = 443;
          ssl = true;
        }];
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:11000"; };
      };

      "home.pablo.tools" = {
        addSSL = true;
        enableACME = true;
        extraConfig = "proxy_buffering off;";
        locations."/" = {
          proxyPass = "http://birne.wireguard:8123";
          proxyWebsockets = true;
        };
      };

      # Minio admin console
      # Set /etc/hosts of client
      "vpn.minio.pablo.tools" = {

        listen = [{
          addr = "192.168.7.1";
          port = 443;
          ssl = true;
        }];

        addSSL = true;
        enableACME = true;

        extraConfig = ''
          # To allow special characters in headers
          ignore_invalid_headers off;
          # Allow any size file to be uploaded.
          # Set to a value such as 1000m; to restrict file size to a specific value
          client_max_body_size 0;
          # To disable buffering
          proxy_buffering off;
        '';

        locations = {
          "/" = {
            proxyPass = "http://birne.wireguard:9001";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              # proxy_set_header Host $host;
              proxy_connect_timeout 300;
              # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
              proxy_http_version 1.1;
              proxy_set_header Connection "";
              chunked_transfer_encoding off;
            '';
          };
        };
      };

      # Minio s3 backend
      # Set /etc/hosts of client
      "vpn.s3.pablo.tools" = {

        listen = [{
          addr = "192.168.7.1";
          port = 443;
          ssl = true;
        }];

        addSSL = true;
        enableACME = true;

        extraConfig = ''
          # To allow special characters in headers
          ignore_invalid_headers off;
          # Allow any size file to be uploaded.
          # Set to a value such as 1000m; to restrict file size to a specific value
          client_max_body_size 0;
          # To disable buffering
          proxy_buffering off;
        '';

        locations = {
          "/" = {
            proxyPass = "http://birne.wireguard:9000";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              # proxy_set_header Host $host;
              proxy_connect_timeout 300;
              # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
              proxy_http_version 1.1;
              proxy_set_header Connection "";
              chunked_transfer_encoding off;
            '';
          };
        };
      };

      # Filebrowser
      # "vpn.files.pablo.tools" = {
      #   listen = [{
      #     addr = "192.168.7.1";
      #     port = 443;
      #     ssl = true;
      #   }];
      #   forceSSL = true;
      #   enableACME = true;
      #   locations."/" = { proxyPass = "http://birne.wireguard:8787"; };
      # };
    };
  };


  # Enable ip forwarding, so wireguard peers can reach eachother
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  pinpox = {
    server = {
      enable = true;
      hostname = "porree";
    };

    wg-client = {
      # enable = true;
      clientIp = "192.168.7.1";
    };

    services.ntfy-sh.enable = true;

    services.alertmanager-ntfy = {
      enable = true;
      httpAddress = "localhost";
      httpPort = "9099";
      ntfyTopic = "https://push.pablo.tools/pinpox_alertmanager";
      ntfyPriority = "default";
      envFile = "${config.lollypops.secrets.files."alertmanager-ntfy/envfile".path}";
    };

    services.matrix-hook = {
      enable = true;
      httpAddress = "localhost";
      matrixHomeserver = "https://matrix.org";
      matrixUser = "@alertus-maximus:matrix.org";
      matrixRoom = "!ilXTQgAfoBlNBuDmsz:matrix.org";
      envFile = "${config.lollypops.secrets.files."matrix-hook/envfile".path}";
      msgTemplatePath = "${
matrix-hook.packages."x86_64-linux".matrix-hook
}/bin/message.html.tmpl";
    };

    services.borg-backup.enable = true;

    # Enable nextcloud configuration
    services.nextcloud.enable = true;

    metrics.node.enable = true;
    metrics.blackbox.enable = true;
    metrics.json.enable = true;
    metrics.restic.enable = true;

    services.monitoring-server = {

      dashboard.enable = true;
      loki.enable = true;
      alertmanager-irc-relay.enable = true;

      enable = true;

      jsonTargets = [
        "http://birne.wireguard/borg-ahorn.json"
        "http://birne.wireguard/borg-birne.json"
        "http://birne.wireguard/borg-kartoffel.json"
        "http://birne.wireguard/borg-kfbox.json"
        "http://birne.wireguard/borg-mega.json"
        "http://birne.wireguard/borg-porree.json"
      ];

      nodeTargets = [
        "ahorn.wireguard:9100"
        "birne.wireguard:9100"
        "kartoffel.wireguard:9100"
        "kfbox.wireguard:9100"
        "mega.wireguard:9100"
        "porree.wireguard:9100"
      ];

      blackboxTargets = [
        "https://pablo.tools"
        "https://megaclan3000.de"
        "https://drone.lounge.rocks"
        # "https://lounge.rocks"
        "https://pass.pablo.tools"
        # "https://vpn.pablo.tools"
        "https://pinpox.github.io/nixos/"
        "https://cache.lounge.rocks/nix-cache-info"
        "https://pads.0cx.de"
        "https://news.0cx.de"
        "https://git.0cx.de"
        "https://irc.0cx.de"
      ];
    };
  };

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.1/24" ];

      listenPort = 51820;

      # Path to the private key file
      privateKeyFile = "${config.lollypops.secrets.files."wireguard/private".path}";
      peers = [
        # kartoffel
        {
          publicKey = "759CaBnvpwNqFJ8e9d5PhJqIlUabjq72HocuC9z5XEs=";
          allowedIPs = [ "192.168.7.3" ];
        }
        # ahorn
        {
          publicKey = "ny2G9iJPBRLSn48fEmcfoIdYi3uHLbJZe3pH1F0/XVg=";
          allowedIPs = [ "192.168.7.2" ];
        }
        # kfbox
        {
          publicKey = "Cykozj24IkXEJ/6ktXxaqqIsxx8xjRMHKmR76lindCc=";
          allowedIPs = [ "192.168.7.5" ];
        }
        # birne
        {
          publicKey = "feDKNR4ZAeEiAsLFJM9FdNi6LHMjnvDj9ap/GRdLKF0=";
          allowedIPs = [
            "192.168.7.4"
            # Also allow local IP's from the home network (e.g. shelly plugs)
            "192.168.2.0/24"
          ];
        }
        # mega
        {
          publicKey = "0IjZ/3dTvz0zaWPhJ9vIAINYG+W0MjbwePUDvhQNCXo=";
          allowedIPs = [ "192.168.7.6" ];
        }
      ];
    };
  };

  # Vaultwarden installed via nixpkgs.
  services.vaultwarden = {
    enable = true;
    config = {
      domain = "https://pass.pablo.tools:443";
      signupsAllowed = false;

      # The rocketPort option should match the value of the port in the reverse-proxy
      rocketPort = 8222;
    };

    # The environment file contiains secrets and is stored in pass
    environmentFile = "${config.lollypops.secrets.files."bitwarden_rs/envfile".path}";
  };
}
