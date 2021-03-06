# Configuration for bob
{ config, pkgs, ... }: {

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
    hostName = "bob"; # Define your hostname.
    useDHCP = false;
    interfaces.ens192.useDHCP = true;
  };

  virtualisation.vmware.guest.enable = true;


  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
