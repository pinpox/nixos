{
  matrix-hook,
  config,
  pkgs,
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
  clan.core.vars.generators."alertmanager-ntfy" = pinpox-utils.mkEnvGenerator [
    "NTFY_USER"
    "NTFY_PASS"
  ];

  # Per-user authelia password generators are now auto-created by the
  # authelia clan service based on auth.user exports from user instances.

  # OIDC client secret for miniflux (generated here, shared to kfbox).
  # client_secret      → raw value for the miniflux OIDC client side
  # client_secret_hash → argon2 hash for the Authelia client_secret_file
  clan.core.vars.generators."miniflux-oidc" = {
    share = true;
    files.client_secret.owner = "authelia-main";
    files.client_secret_hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [
      coreutils
      openssl
      authelia
      gnused
    ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      authelia crypto hash generate argon2 --password "$(cat $out/client_secret)" \
        | sed 's/^Digest: //' > $out/client_secret_hash
    '';
  };

  # OIDC client secret for forgejo (generated here, shared to forgejo host).
  # client_secret      → raw value for the forgejo OIDC client side
  # client_secret_hash → argon2 hash for the Authelia client_secret_file
  clan.core.vars.generators."forgejo-oidc" = {
    share = true;
    files.client_secret.owner = "authelia-main";
    files.client_secret_hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [
      coreutils
      openssl
      authelia
      gnused
    ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      authelia crypto hash generate argon2 --password "$(cat $out/client_secret)" \
        | sed 's/^Digest: //' > $out/client_secret_hash
    '';
  };

  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

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
      opencrow.enable = true;
      # Authelia is now a clan service (clan-service-modules/authelia).
      # Configuration is in inventory.nix.
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

      # Enable paperless-ngx document management
      paperless.enable = true;

      # Enable nextcloud configuration
      nextcloud.enable = true;

      # Enable OpenCloud (uses Authelia OIDC)
      opencloud.enable = true;

    };
  };
}
