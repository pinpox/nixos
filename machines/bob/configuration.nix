# Configuration for bob
{ self, ... }: {

  imports = [ ./hardware-configuration.nix ];

  pinpox = {
    server = {
      enable = true;
      hostname = "bob";
      homeConfig = self.inputs.nixos-home.nixosModules.server;
    };

    services = {
      binary-cache.enable = true;
      droneci.enable = true;
      droneci.runner-exec.enable = true;
      droneci.runner-docker.enable = true;
      monitoring-server.http-irc.enable = true;
    };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    (builtins.fetchurl {
      url = "https://github.com/MayNiklas.keys";
      sha256 = "180458fg6i6sbqmyz18rb1hsq4226zdivqz86x9dwkv02fqvkygw";
    })
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };
    cleanTmpDir = true;
  };

  networking = {

    # DHCP
    useDHCP = false;
    interfaces.ens192.useDHCP = true;

    # Open ports in the firewall.
    firewall.allowedTCPPorts = [ 80 443 ];

    # Make the host resolv the cache to itself
    extraHosts = ''
      127.0.0.1 cache.lounge.rocks
    '';
  };

  virtualisation.vmware.guest.enable = true;

  # Workaround for problems with the dockerized CI
  systemd.enableUnifiedCgroupHierarchy = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
