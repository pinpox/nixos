{ self, ... }: {

  imports = [ ./hardware-configuration.nix ];

  pinpox = {

    server = {
      enable = true;
      hostname = "kfbox";
      homeConfig = self.inputs.nixos-home.nixosModules.server;
    };

    wg-client = {
      enable = true;
      clientIp = "192.168.7.5";
    };

    services = {
      go-karma-bot.enable = true;
      hedgedoc.enable = true;
      mattermost.enable = true;
      thelounge.enable = true;
    };

    metrics.node.enable = true;
  };

  nix.autoOptimiseStore = true;

  services.qemuGuest.enable = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;
  # services.udev.packages = [ pkgs.yubikey-personalization ];

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

  programs.ssh.startAgent = false;

  environment.systemPackages = with pkgs; [
    ctags
    git
    gnumake
    go
    htop
    neovim
    nixfmt
    python
    ripgrep
    wget
  ];

  security.acme.acceptTerms = true;
  security.acme.email = "letsencrypt@pablo.tools";

  # Block anything that is not HTTP(s) or SSH.
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 80 443 22 ];

    # interfaces.wg0.allowedTCPPorts = [ 2812 ];
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";

    # commonHttpConfig = ''
    #   server_names_hash_bucket_size 128;
    # '';

    # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
    # provided by Let's Encrypt via ACME. Generation and renewal is automatic
    # if DNS is set up correctly for the (sub-)domains.
    virtualHosts = {

      # "0cx.de" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   root = "/var/www/";
      # };

      # The Lounge IRC
      "irc.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9090"; };
      };

      # Pads
      "pads.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:3000"; };
      };

      # Mattermost
      "mm.0cx.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8065";
          proxyWebsockets = true;

          extraConfig = ''
            proxy_pass_request_headers on;
            add_header Access-Control-Allow-Origin *;
            client_max_body_size 50M;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Frame-Options SAMEORIGIN;
            proxy_buffers 256 16k;
            proxy_buffer_size 16k;
            proxy_read_timeout 600s;
            proxy_cache_revalidate on;
            proxy_cache_min_uses 2;
            proxy_cache_use_stale timeout;
            proxy_cache_lock on;
          '';
        };

        locations."~ /api/v[0-9]+/(users/)?websocket$" = {
          extraConfig = ''
            proxy_pass_request_headers on;
            add_header Access-Control-Allow-Origin *;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            client_max_body_size 50M;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Frame-Options SAMEORIGIN;
            proxy_buffers 256 16k;
            proxy_buffer_size 16k;
            client_body_timeout 60;
            send_timeout 300;
            lingering_timeout 5;
            proxy_connect_timeout 90;
            proxy_send_timeout 300;
            proxy_read_timeout 90s;
          '';

          proxyPass = "http://127.0.0.1:8065";
          proxyWebsockets = true;
        };
      };
    };
  };
}
