# Configuration for kartoffel

{ config, pkgs, inputs, ... }: {

  # Define the hostname
  networking.hostName = "kartoffel";

  # Video driver for nvidia graphics card
  services.xserver.videoDrivers = [ "nvidia" ];

  boot = {
    # Use GRUB2 as EFI boot loader.
    loader.grub.useOSProber = true;

    blacklistedKernelModules = [ "nouveau" ];

    # Encrypted drive to be mounted by the bootloader. Path of the device will
    # have to be changed for each install.
    initrd.luks.devices = {
      root = {
        # Get UUID from blkid /dev/sda2
        device = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
        preLVM = true;
        allowDiscards = true;
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # borgbackup
    arandr
    ctags
    git
    gnumake
    go
    killall
    neovim
    nixfmt
    nodejs
    openvpn
    python
    ripgrep
    ruby
    wget
  ];


  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  programs.dconf.enable = true;

  # Enable Wireguard
  networking.wireguard.interfaces.wg0.ips = [ "192.168.7.3/24" ];



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
