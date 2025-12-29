{
  matrix-hook,
  config,
  alertmanager-ntfy,
  pinpox-utils,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    alertmanager-ntfy.nixosModules.default
    ./caddy.nix
    # ./retiolum.nix
  ];

  clan.core.networking.targetHost = "94.16.108.229";
  networking.hostName = "porree";

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a03:4000:51:aa3::1";
        prefixLength = 64;
      }
    ];
  };

  clan.core.vars.generators."matrix-hook" = pinpox-utils.mkEnvGenerator [ "MX_TOKEN" ];
  clan.core.vars.generators."alertmanager-ntfy" = pinpox-utils.mkEnvGenerator [
    "NTFY_USER"
    "NTFY_PASS"
  ];

  services.qemuGuest.enable = true;

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

    interfaces.wg-clan.allowedTCPPorts = [
      2812
      8086 # InfluxDB
    ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  programs.ssh.startAgent = false;

  services.alertmanager-ntfy = {
    enable = true;
    httpAddress = "localhost";
    httpPort = "9099";
    ntfyTopic = "https://push.pablo.tools/pinpox_alertmanager";
    ntfyPriority = "default";
    envFile = "${config.clan.core.vars.generators."alertmanager-ntfy".files."envfile".path}";
  };

  pinpox = {

    services = {

      # kanidm.enable = true;
       authelia.enable = true;
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

        enable = true;
        dashboard.enable = true;
        loki.enable = true;
        alertmanager-irc-relay.enable = true;

        blackboxTargets = [
          "https://pablo.tools"
          "https://megaclan3000.de"
          "https://build.lounge.rocks"
          # "https://lounge.rocks"
          # "https://vpn.pablo.tools"
          "https://${config.pinpox.services.vaultwarden.host}" # Vaultwarden
          "https://pinpox.github.io/nixos/"
          "https://cache.lounge.rocks/nix-cache/nix-cache-info"
          # "https://pads.0cx.de"
          "https://news.0cx.de"
          # Gitea (on kfbox with host set to default vaulue)
          "https://${config.pinpox.services.gitea.host}"
          "https://irc.0cx.de"
        ];
      };
    };

    metrics = {
      blackbox.enable = true;
      json.enable = true;
    };
  };
}
