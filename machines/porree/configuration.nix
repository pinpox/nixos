{ self, ... }:
{ pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    self.inputs.matrix-hook.nixosModules.matrix-hook
  ];

  # services.influxdb2.enable = true;
  # services.influxdb2.settings = { };

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
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";
    recommendedProxySettings = true;

    # Needed for vaultwarden, it seems to have trouble serving scripts for
    # the frontend without it.
    commonHttpConfig = ''
      server_names_hash_bucket_size 128;

      log_format json_analytics escape=json '{'
        '"msec": "$msec", '                                         # request unixtime in seconds with a milliseconds resolution
        '"connection": "$connection", '                             # connection serial number
        '"connection_requests": "$connection_requests", '           # number of requests made in connection
        '"pid": "$pid", '                                           # process pid
        '"request_id": "$request_id", '                             # the unique request id
        '"request_length": "$request_length", '                     # request length (including headers and body)
        '"remote_addr": "$remote_addr", '                           # client IP
        '"remote_user": "$remote_user", '                           # client HTTP username
        '"remote_port": "$remote_port", '                           # client port
        '"time_local": "$time_local", '
        '"time_iso8601": "$time_iso8601", '                         # local time in the ISO 8601 standard format
        '"request": "$request", '                                   # full path no arguments if the request
        '"request_uri": "$request_uri", '                           # full path and arguments if the request
        '"args": "$args", '                                         # args
        '"status": "$status", '                                     # response status code
        '"body_bytes_sent": "$body_bytes_sent", '                   # the number of body bytes exclude headers sent to a client
        '"bytes_sent": "$bytes_sent", '                             # the number of bytes sent to a client
        '"http_referer": "$http_referer", '                         # HTTP referer
        '"http_user_agent": "$http_user_agent", '                   # user agent
        '"http_x_forwarded_for": "$http_x_forwarded_for", '         # http_x_forwarded_for
        '"http_host": "$http_host", '                               # the request Host: header
        '"server_name": "$server_name", '                           # the name of the vhost serving the request
        '"request_time": "$request_time", '                         # request processing time in seconds with msec resolution
        '"upstream": "$upstream_addr", '                            # upstream backend server for proxied requests
        '"upstream_connect_time": "$upstream_connect_time", '       # upstream handshake time incl. TLS
        '"upstream_header_time": "$upstream_header_time", '         # time spent receiving upstream headers
        '"upstream_response_time": "$upstream_response_time", '     # time spend receiving upstream body
        '"upstream_response_length": "$upstream_response_length", ' # upstream response length
        '"upstream_cache_status": "$upstream_cache_status", '       # cache HIT/MISS where applicable
        '"ssl_protocol": "$ssl_protocol", '                         # TLS protocol
        '"ssl_cipher": "$ssl_cipher", '                             # TLS cipher
        '"scheme": "$scheme", '                                     # http or https
        '"request_method": "$request_method", '                     # request method
        '"server_protocol": "$server_protocol", '                   # request protocol, like HTTP/1.1 or HTTP/2.0
        '"pipe": "$pipe", '                                         # "p" if request was pipelined, "." otherwise
        '"gzip_ratio": "$gzip_ratio", '
        '"http_cf_ray": "$http_cf_ray",'
        '"geoip_country_code": "$geoip_country_code"'
      '}';

       access_log /var/log/nginx/json_access.log json_analytics;
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
        basicAuthFile = "/run/keys/alerts_htpasswd";
      };

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

  # Deploy htpaswd file for external alerts
  # Generate with: mkpasswd -m sha-512 (save as username:$6$E7UzqcDh3$Xi...)
  # Test with: curl -X POST -d'test' https://user:password@notify.pablo.tools/plain
  users.users.nginx = { extraGroups = [ "keys" ]; };
  krops.secrets.files = {
    alerts_htpasswd = {
      owner = "nginx";
      source-path = "/var/src/secrets/matrix-hook/alerts.passwd";
    };
  };

  pinpox = {
    server = {
      enable = true;
      hostname = "porree";
    };

    wg-client = {
      # enable = true;
      clientIp = "192.168.7.1";
    };

    services.matrix-hook = {
      enable = true;
      httpAddress = "localhost";
      matrixHomeserver = "https://matrix.org";
      matrixUser = "@alertus-maximus:matrix.org";
      matrixRoom = "!ilXTQgAfoBlNBuDmsz:matrix.org";
      envFile = "/var/src/secrets/matrix-hook/envfile";
      msgTemplatePath = "${
          self.inputs.matrix-hook.packages."x86_64-linux".matrix-hook
        }/bin/message.html.tmpl";
    };

    services.borg-backup.enable = true;

    # Enable nextcloud configuration
    services.nextcloud.enable = true;

    metrics.node.enable = true;
    metrics.blackbox.enable = true;
    metrics.json.enable = true;

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
        "https://lounge.rocks"
        "https://pass.pablo.tools"
        # "https://vpn.pablo.tools"
        "https://pinpox.github.io/nixos/"
        "https://cache.lounge.rocks/nix-cache-info"
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
      signupsAllowed = true;

      # The rocketPort option should match the value of the port in the reverse-proxy
      rocketPort = 8222;
    };

    # The environment file contiains secrets and is stored in pass
    environmentFile = /var/src/secrets/bitwarden_rs/envfile;
  };
}
