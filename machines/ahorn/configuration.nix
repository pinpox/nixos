# Configuration file for ahorn

{ config, pkgs, inputs, ... }: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Default users
    #../../common/user-profiles/root.nix
    ../../common/user-profiles/pinpox.nix

    # Include reusables
    # ../../common/borg/home.nix
    ../../common/bluetooth.nix
    ../../common/environment.nix
    ../../common/fonts.nix
    ../../common/locale.nix
    ../../common/networking.nix
    ../../common/openssh.nix
    ../../common/sound.nix
    ../../common/virtualization.nix
    ../../common/xserver.nix
    ../../common/yubikey.nix
    ../../common/zsh.nix
  ];

  # Define the hostname
  networking.hostName = "ahorn";

  boot = {
    # Use GRUB2 as EFI boot loader.
    loader.grub.enable = true;
    loader.grub.version = 2;
    loader.grub.device = "nodev";
    loader.grub.efiSupport = true;
    loader.grub.useOSProber = true;
    loader.efi.canTouchEfiVariables = true;

    # Encrypted drive to be mounted by the bootloader. Path of the device will
    # have to be changed for each install.

    initrd.luks.devices = {
      root = {
        # Get UUID from blkid /dev/sda2
        device = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
        preLVM = true;
        allowDiscards = true;
      };
    };

    # /tmp is cleaned after each reboot
    cleanTmpDir = true;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Users allowed to run nix
    allowedUsers = [ "root" ];
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

  programs.steam.enable = true;

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.2/24" ];

      # Path to the private key file
      privateKeyFile = "/var/src/secrets/wireguard/private";
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
