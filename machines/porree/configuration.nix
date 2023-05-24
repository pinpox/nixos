{ lib, matrix-hook, config, retiolum, alertmanager-ntfy, ... }: {

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

  # Often hangs
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  # services.influxdb2.enable = true;
  # services.influxdb2.settings = { };

  lollypops.secrets.files = {
    "matrix-hook/envfile" = { };
    "alertmanager-ntfy/envfile" = { };
    "bitwarden_rs/envfile" = { };
    "wireguard/private" = { };

    "caddy/basicauth_beta" = { };
    "caddy/basicauth_3dprint" = { };
    "caddy/basicauth_notify" = { };

    # "nginx/blog.passwd" = {
    #   path = "/var/www/blog.passwd";
    #   owner = "nginx";
    # };

    # "nginx/3dprint.passwd" = {
    #   path = "/var/www/3dprint.passwd";
    #   owner = "nginx";
    # };
    # "matrix-hook/alerts.passwd" = {
    #   path = "/var/lib/matrix-hook/alerts.passwd";
    #   owner = "nginx";
    # };
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

  # The difference between {$ and {env. is that {$ is evaluated before Caddyfile
  # parsing begins, and {env. is evaluated at runtime. This matters if your
  # config is adapted in a different environment from which it is being run.

  # To generated basic auth env vars:
  # caddy hash-password --plaintext "hunter2"
  # BASICAUTH_NOTIFY_PABLO_TOOLS='username $2a$XXXXXXXXXXXXXXXXXXXXXXXXXX'
  # Test with: curl -X POST -d'test' https://username:hunter2@notify.pablo.tools/plain

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.lollypops.secrets.files."caddy/basicauth_beta".path
    config.lollypops.secrets.files."caddy/basicauth_3dprint".path
    config.lollypops.secrets.files."caddy/basicauth_notify".path
  ];

  # services.nginx.enable = false;

  services.caddy = {
    enable = true;

    # globalConfig = ''

    #   @vpnonly {
    #   remote_ip 192.168.0.0/16 172.168.7.0/16
    #   }
    # '';

    # Handle errors for all pages
    # respond "{err.status_code} {err.status_text}"
    extraConfig = ''
      :443, :80 {
        handle_errors {
         respond * "This page does not exist or is not for your eyes." {
           close
         }
        }
      }
    '';

    virtualHosts = {

      # Homepage
      "pablo.tools".extraConfig = ''
        root * /var/www/pablo-tools
        file_server
        encode zstd gzip
      '';

      # Homepage (dev)
      "beta.pablo.tools".extraConfig = ''
        root * /var/www/pablo-tools-beta
        file_server
        encode zstd gzip
        basicauth {
          {$BASICAUTH_BETA_PABLO_TOOLS}
        }
      '';

      # Camera (read-only) stream
      "3dprint.pablo.tools".extraConfig = ''
        reverse_proxy 192.168.2.121:8081
        basicauth {
          {$BASICAUTH_3DPRINT_PABLO_TOOLS}
        }
      '';

      # Notifications API
      "notify.pablo.tools".extraConfig = ''
        reverse_proxy 127.0.0.1:11000
        basicauth {
          {$BASICAUTH_NOTIFY_PABLO_TOOLS}
        }
      '';

      # Password manager (vaultwarden) instance
      "pass.pablo.tools".extraConfig = "reverse_proxy 127.0.0.1:8222";

      # Photo gallery
      "photos.pablo.tools".extraConfig = "reverse_proxy 127.0.0.1:7788";

      # Grafana
      "status.pablo.tools".extraConfig = "reverse_proxy 127.0.0.1:9005";

      # Home-assistant
      "home.pablo.tools".extraConfig = "reverse_proxy birne.wireguard:8123";

      # Octoprint (set /etc/hosts for clients)
      "vpn.octoprint.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 192.168.2.121:5000
      '';

      # Alertmanager
      "vpn.alerts.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:9093
      '';

      # Prometheus
      "vpn.prometheus.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:9090
      '';

      # ntfy
      "vpn.notify.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:11000
      '';

      # Minio admin console
      "vpn.minio.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly birne.wireguard:9001
      '';

      # Minio s3 backend
      "vpn.s3.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly birne.wireguard:9000
      '';

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
      DOMAIN = "https://pass.pablo.tools";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = "true";
      # The rocketPort option should match the value of the port in the reverse-proxy
      ROCKET_PORT = 8222;
    };

    # The environment file contiains secrets and is stored in pass
    environmentFile = "${config.lollypops.secrets.files."bitwarden_rs/envfile".path}";
  };
}
