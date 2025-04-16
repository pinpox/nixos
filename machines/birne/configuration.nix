# Configuration for birne
{
  pkgs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  clan.core.networking.targetHost = "192.168.101.221";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # Host forwards incoming wg connections to the local network so we can reach LAN devices via wireguard. E.g. for retrieving stats directly from smart-home devices
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  boot.supportedFilesystems = {
    btrfs = true;
    zfs = true;
  };

  pinpox = {

    server = {
      enable = true;
      hostname = "birne";
    };

    services = {
      minio.enable = true;
      home-assistant.enable = true;
    };

    defaults = {
      lvm-grub.enable = true;
      environment.enable = true;
      locale.enable = true;
      nix.enable = true;
    };

    metrics.node.enable = true;
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  # Access locally via:
  # https://birne:8443/manage/
  services.unifi = {
    enable = false;

    # 6 is latest supported for my access points. Beware that this will build
    # an older version of mongodb (from source), which may cause slow rebuilds
    # if it's not cached.
    unifiPackage = pkgs.unifi6;

    # Open required ports
    openFirewall = true;
    # tcp/8080  # Port for UAP to inform controller.
    # tcp/8880  # Port for HTTP portal redirect, if guest portal is enabled.
    # tcp/8843  # Port for HTTPS portal redirect, ditto.
    # tcp/6789  # Port for UniFi mobile speed test.
    # udp/3478  # UDP port used for STUN.
    # udp/10001 # UDP port used for device discovery.
  };

  # Waiting until seafile/seahub is fixed
  # services.seafile = {
  #   enable = true;
  #
  #   adminEmail = "seafile@pablo.tools";
  #
  #   # ccnetSettings
  #   # https://manual.seafile.com/config/ccnet-conf/
  #   ccnetSettings.General.SERVICE_URL = "https://cloud.pablo.tools";
  #
  #   # dataDir = "/var/lib/seafile/data";
  #
  #   # gc.dates
  #   # gc.enable
  #   # gc.persistent
  #   # gc.randomizedDelaySec
  #
  #   initialAdminPassword = "changeme";
  #
  #   seafileSettings = {
  #     # fileserver.port = 8082;
  #     # fileserver.host = "ipv4:127.0.0.1";
  #   };
  #
  #   # seahubAddress = "unix:/run/seahub/gunicorn.sock";
  #
  #   # https://manual.seafile.com/config/seahub_settings_py/
  #   # seahubExtraConf =
  #   # ''
  #   #   CSRF_TRUSTED_ORIGINS = ["https://example.com"]
  #   # ''
  #
  #   # seahubPackage
  #   # workers
  # };

  # Open ports in the firewall.
  networking.firewall = {

    allowedUDPPorts = [ 3478 ];
    allowedTCPPorts = [
      80
      443
      # 8443
      4533
    ];
  };
}
