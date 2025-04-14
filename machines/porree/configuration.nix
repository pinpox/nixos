{
  matrix-hook,
  config,
  alertmanager-ntfy,
  pinpox-utils,
  pkgs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    alertmanager-ntfy.nixosModules.default
    ./caddy.nix
    ./retiolum.nix
  ];

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a03:4000:51:aa3::1";
        prefixLength = 64;
      }
    ];
  };

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

  clan.core.vars.generators."matrix-hook" = pinpox-utils.mkEnvGenerator [ "MX_TOKEN" ];
  clan.core.vars.generators."alertmanager-ntfy" = pinpox-utils.mkEnvGenerator [
    "NTFY_USER"
    "NTFY_PASS"
  ];

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

  # Enable ip forwarding, so wireguard peers can reach eachother
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  services.alertmanager-ntfy = {
    enable = true;
    httpAddress = "localhost";
    httpPort = "9099";
    ntfyTopic = "https://push.pablo.tools/pinpox_alertmanager";
    ntfyPriority = "default";
    envFile = "${config.clan.core.vars.generators."alertmanager-ntfy".files."envfile".path}";
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
        envFile = "${config.clan.core.vars.generators."matrix-hook".files."envfile".path}";
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
