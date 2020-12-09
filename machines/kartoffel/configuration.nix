# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/machines/kartoffel/hardware-configuration.nix

    # Default users
    #../../common/user-profiles/root.nix
    <common/user-profiles/pinpox.nix>

    # Include reusables
    # <common/borg/home.nix>
    <common/sound.nix>
    <common/openssh.nix>
    <common/environment.nix>
    <common/xserver.nix>
    <common/networking.nix>
    <common/bluetooth.nix>
    <common/fonts.nix>
    <common/locale.nix>
    <common/yubikey.nix>
    <common/virtualization.nix>
    <common/zsh.nix>
  ];

  # Define the hostname
  networking.hostName = "kartoffel";

  # Video driver for nvidia graphics card
  services.xserver.videoDrivers = [ "nvidia" ];

  boot = {
    # Use GRUB2 as EFI boot loader.
    loader.grub.enable = true;
    loader.grub.version = 2;
    loader.grub.device = "nodev";
    loader.grub.efiSupport = true;
    loader.grub.useOSProber = true;
    loader.efi.canTouchEfiVariables = true;

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

    # /tmp is cleaned after each reboot
    cleanTmpDir = true;
  };

  # Users allowed to run nix
  nix.allowedUsers = [ "root" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    python
    ctags
    openvpn
    ruby
    python
    # borgbackup
    go
    ripgrep
    nodejs
    killall
    arandr
    wget
    neovim
    git
    gnumake
    nixfmt
  ];

  programs.dconf.enable = true;

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.2/24" ];

      # Path to the private key file
      privateKeyFile = toString <secrets/wireguard/private>;
      peers = [{
        # Public key of the server (not a file path).
        publicKey = "XKqEk5Hsp3SRVPrhWD2eLFTVEYb9NYRky6AermPG8hU=";

        # Don't forward all the traffic via VPN, only particular subnets
        allowedIPs = [ "192.168.7.0/24" ];

        # Server IP and port.
        endpoint = "vpn.pablo.tools:51820";

        # Send keepalives every 25 seconds. Important to keep NAT tables
        # alive.
        persistentKeepalive = 25;
      }];
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nixpkgs = { config.allowUnfree = true; };

  # Clean up old generations after 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

