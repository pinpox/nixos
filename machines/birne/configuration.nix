# Configuration for birne
{
  config,
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

  networking.hostName = "birne";

  pinpox = {

    services = {
      unifi-controller.enable = true;
      minio.enable = true;
      home-assistant.enable = true;
    };

    defaults = {
      lvm-grub.enable = true;
      environment.enable = true;
      locale.enable = true;
      nix.enable = true;
    };

  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  networking.firewall = {
    allowedUDPPorts = [ 3478 ];
    allowedTCPPorts = [
      80
      443
      4533
    ];
  };

  services.navidrome = {

    enable = true;

    settings.Port = 4533;
    settings.Address = "${
      (builtins.readFile (
        config.clan.core.settings.directory + "/vars/per-machine/birne/wireguard-wg-clan-ip/ipv4/value"
      ))
    }";

    settings.MusicFolder = "/mnt/data/admin/ARCHIVE/Musik/Alphabetisch";

    # openFirewall
    # environmentFile
  };

}
