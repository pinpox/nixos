# Configuration file for ahorn
{ config, pkgs, inputs, ... }: {

  # Define the hostname
  networking.hostName = "ahorn";

  # TODO Create option in wireguard module for setting this
  # Determines the IP address and subnet of the client's end of the
  # tunnel interface.
  networking.wireguard.interfaces.wg0.ips = [ "192.168.7.2/24" ];

  # TODO Create option in lvm-grub-luks module for setting this
  # Encrypted drive to be mounted by the bootloader. Path of the device will
  # have to be changed for each install.
  # Get UUID from blkid /dev/sda2
  boot.initrd.luks.devices.root.device =
    "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";

  # TODO Create lvm-grub-luks module
  boot = {
    initrd.luks.devices = {
      root = {
        preLVM = true;
        allowDiscards = true;
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    arandr
    borgbackup
    ctags
    docker
    docker-compose
    git
    gnumake
    go
    gparted
    killall
    neovim
    nixfmt
    nodejs
    ntfs3g
    openvpn
    python
    ripgrep
    ruby
    wget
  ];

  programs.dconf.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
