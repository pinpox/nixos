{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.desktop;
in {

  imports = [
    ../irc-bot

    ../bluetooth
    ../environment
    ../locale

    ../user-profiles/pinpox.nix
    ../borg/default.nix
    ../lvm-grub.nix
    ../networking.nix
    ../openssh.nix
    ../sound.nix
    ../virtualisation
    ../xserver.nix
    ../yubikey.nix
    ../zsh.nix
    ../nix-common.nix
    ../wireguard-client.nix
  ];

  options.pinpox.desktop = {
    enable = mkEnableOption "Enable the default desktop configuration";

    homeConfig = mkOption {
      type = types.attrs;
      default = null;
    };

    wireguardIp = mkOption {
      type = types.str;
      default = null;
    };

    stateVersion = mkOption {
      type = types.str;
      default = "20.03";
    };

    hostname = mkOption {
      type = types.str;
      default = null;
    };

    bootDevice = mkOption {
      type = types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {

    home-manager.users.pinpox = cfg.homeConfig;

    pinpox = {
      defaults = {
        environment.enable = true;
        bluetooth.enable = true;
        locale.enable = true;
      };

      virtualisation = {
        docker.enable = true;
        virtualbox.enable = true;
      };

      services.xserver.enable = true;
      wg-client = {
        enable = true;
        clientIp = cfg.wireguardIp;
      };
    };

    # here goes the configuration, reference values with cfg.varname
    # e.g. networking.wireguard.interfaces = { };

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

    boot = {
      # Use GRUB2 as EFI boot loader.
      loader.grub.useOSProber = true;

      # Encrypted drive to be mounted by the bootloader. Path of the device will
      # have to be changed for each install.
      initrd.luks.devices = {
        root = {
          # Get UUID from blkid /dev/sda2
          device = cfg.bootDevice;
          preLVM = true;
          allowDiscards = true;
        };
      };
    };

    # Define the hostname
    networking.hostName = cfg.hostname;

    programs.dconf.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = cfg.stateVersion; # Did you read the comment?
  };
}
