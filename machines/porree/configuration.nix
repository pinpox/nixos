{
  matrix-hook,
  config,
  pkgs,
  lib,
  pinpox-utils,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    ./caddy.nix
    # ./retiolum.nix
    ../../modules/opencrow
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

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  # Postgres is enabled by clan-core monitoring (grafana). Pin the major
  # version matching the on-disk cluster (/var/lib/postgresql/17); otherwise
  # it is derived from stateVersion 20.03 -> postgresql_11 (removed).
  services.postgresql.package =  pkgs.postgresql_17;

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

  pinpox = {

    services = {

      pinpox-web.enable = true;

      opencrow.enable = true;
      vaultwarden.enable = true;

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
      nextcloud.enable = false;

    };
  };
}
