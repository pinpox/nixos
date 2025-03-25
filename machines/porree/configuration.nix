{
  lib,
  matrix-hook,
  config,
  retiolum,
  alertmanager-ntfy,
  pkgs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    alertmanager-ntfy.nixosModules.default
    retiolum.nixosModules.retiolum
  ];

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a03:4000:51:aa3::1";
        prefixLength = 64;
      }
    ];
  };

  lollypops.deployment.ssh.host = "94.16.108.229";
  clan.core.networking.targetHost = "94.16.108.229";

  clan.core.vars.generators."wireguard" = {

    files.publickey.secret = false;
    files.privatekey = { };

    runtimeInputs = with pkgs; [ wireguard-tools ];

    script = ''
      wg genkey > $out/privatekey
      wg pubkey < $out/privatekey > $out/publickey
    '';
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
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
    allowedTCPPorts = [
      80
      443
      22
    ];
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

  services.alertmanager-ntfy = {
    enable = true;
    httpAddress = "localhost";
    httpPort = "9099";
    ntfyTopic = "https://push.pablo.tools/pinpox_alertmanager";
    ntfyPriority = "default";
    envFile = "${config.lollypops.secrets.files."alertmanager-ntfy/envfile".path}";
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

    services = {
      vaultwarden.enable = true;
      ntfy-sh.enable = true;

      matrix-hook = {
        enable = true;
        httpAddress = "localhost";
        matrixHomeserver = "https://matrix.org";
        matrixUser = "@alertus-maximus:matrix.org";
        matrixRoom = "!ilXTQgAfoBlNBuDmsz:matrix.org";
        envFile = "${config.lollypops.secrets.files."matrix-hook/envfile".path}";
        msgTemplatePath = "${matrix-hook.packages."x86_64-linux".matrix-hook}/bin/message.html.tmpl";
      };

      # Enable nextcloud configuration
      nextcloud.enable = true;

      monitoring-server = {

        dashboard.enable = true;
        loki.enable = false;
        alertmanager-irc-relay.enable = true;

        enable = true;

        blackboxTargets = [
          "https://pablo.tools"
          "https://megaclan3000.de"
          "https://build.lounge.rocks"
          # "https://lounge.rocks"
          # "https://vpn.pablo.tools"
          "https://${config.pinpox.services.vaultwarden.host}" # Vaultwarden
          "https://pinpox.github.io/nixos/"
          "https://cache.lounge.rocks/nix-cache/nix-cache-info"
          "https://pads.0cx.de"
          "https://news.0cx.de"
          # Gitea (on kfbox with host set to default vaulue)
          "https://${config.pinpox.services.gitea.host}"
          "https://irc.0cx.de"
        ];
      };
    };

    metrics = {
      node.enable = true;
      blackbox.enable = true;
      json.enable = true;
      restic.enable = true;
    };
  };

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.1/24" ];

      listenPort = 51820;
      privateKeyFile = config.clan.core.vars.generators."wireguard".files.privatekey.path;

      peers =
        let
          mkWgPeer = host: IPs: {
            publicKey = (
              builtins.readFile (
                config.clan.core.settings.directory + "/vars/per-machine/${host}/wireguard/publickey/value"
              )
            );
            allowedIPs = IPs;
            persistentKeepalive = 25;
          };
        in
        [
          (mkWgPeer "kartoffel" [ "192.168.7.3" ])
          (mkWgPeer "ahorn" [ "192.168.7.2" ])
          (mkWgPeer "kfbox" [ "192.168.7.5" ])
          (mkWgPeer "birne" [
            "192.168.7.4"
            "192.168.2.0/24"
          ])
          # (mkWgPeer "mega" [ "192.168.7.6" ])
          # {
          #    mayniklas GPU
          #   publicKey = "aD6SXOOB3JJnRXUvB09yXlf/2kyFe1TZ5HEx2TIJKTQ=";
          #   allowedIPs = [ "192.168.7.7" ];
          #   persistentKeepalive = 25;
          # }
        ];
    };
  };
}
