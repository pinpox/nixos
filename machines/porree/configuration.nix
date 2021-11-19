{ self, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
    self.inputs.ha-relay.nixosModules.ha-relay
  ];

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

    interfaces.wg0.allowedTCPPorts = [ 2812 ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  programs.ssh.startAgent = false;

  security.acme.acceptTerms = true;
  security.acme.email = "letsencrypt@pablo.tools";

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";
    recommendedProxySettings = true;

    # Needed for vaultwarden, it seems to have trouble serving scripts for
    # the frontend without it.
    commonHttpConfig = ''
      server_names_hash_bucket_size 128;
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
      };

      # Password manager (vaultwarden) instance
      "pass.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:8222"; };
      };

      # Graphana
      "status.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9005"; };
      };

      # Alertmanager
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

      "home.pablo.tools" = {
        addSSL = true;
        enableACME = true;
        extraConfig = "proxy_buffering off;";
        locations."/" = {
          proxyPass = "http://birne.wireguard:8123";
          proxyWebsockets = true;
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

    services.home-assistant-grafana-relay = {
      enable = true;
      listenHost = "localhost";
      haUri = "http://home.pablo.tools/api/services/notify/notify";
      listenPort = "12000";
      envFile = "/var/src/secrets/ha-relay/envfile";
    };

    services.borg-backup.enable = true;

    # Enable nextcloud configuration
    services.nextcloud.enable = true;

    metrics.node.enable = true;
    metrics.blackbox.enable = true;

    services.monitoring-server = {

      dashboard.enable = true;
      loki.enable = true;

      enable = true;
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
        "https://lounge.rocks"
        "https://pass.pablo.tools"
        # "https://vpn.pablo.tools"
        "https://pinpox.github.io/nixos/"
        "https://pads.0cx.de"
        "https://news.0cx.de"
        "https://mm.0cx.de"
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
      privateKeyFile = toString /var/src/secrets/wireguard/private;
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
          allowedIPs = [ "192.168.7.4" ];
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
      signupsAllowed = true;

      # The rocketPort option should match the value of the port in the reverse-proxy
      rocketPort = 8222;
    };

    # The environment file contiains secrets and is stored in pass
    environmentFile = /var/src/secrets/bitwarden_rs/envfile;
  };
}
