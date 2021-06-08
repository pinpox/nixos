{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.desktop;
in {

  imports = [ ../../users/pinpox.nix ];

  options.pinpox.desktop = {
    enable = mkEnableOption "Enable the default desktop configuration";

    homeConfig = mkOption {
      type = types.attrs;
      default = null;
      example = "{}";
      description = "Main users account home-manager configuration for the host";
    };

    wireguardIp = mkOption {
      type = types.str;
      default = null;
      description = "Wireguard for the wg0 VPN";
      example = "192.168.7.XXX";
    };

    stateVersion = mkOption {
      type = types.str;
      default = "20.03";
      example = "21.09";
      description = "NixOS state-Version";
    };

    hostname = mkOption {
      type = types.str;
      default = null;
      example = "deepblue";
      description = "hostname to identify the instance";
    };

    bootDevice = mkOption {
      type = types.str;
      default = null;
      description = "Path of the underlying luks-encrypted root.\nGet UUID from e.g.\nblkid /dev/sda2";
      example = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
    };
  };

  config = mkIf cfg.enable {

    home-manager.users.pinpox = cfg.homeConfig;

    pinpox = {
      defaults = {
        bluetooth.enable = true;
        environment.enable = true;
        fonts.enable = true;
        locale.enable = true;
        networking.enable = true;
        nix.enable = true;
        sound.enable = true;
        zsh.enable = true;
        yubikey.enable = true;
        lvm-grub.enable = true;
      };

      virtualisation = {
        docker.enable = true;
        virtualbox.enable = true;
      };

      services = {
        xserver.enable = true;
        openssh.enable = true;
      };

      metrics.node.enable = true;

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
      recursive
      lm_sensors
      arandr
      jetbrains-mono
      ctags
      git
      gnumake
      go
      killall
      neovim
      nixfmt
      wezterm-nightly
      hello-custom-test
      nodejs
      openvpn
      python
      ripgrep
      ruby
      wget
    ];

services.logind.extraConfig = ''
    RuntimeDirectorySize=20G
  '';

    boot = {
      # Use GRUB2 as EFI boot loader.
      loader.grub.useOSProber = true;

      tmpOnTmpfs = false;

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
    services.gvfs.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = cfg.stateVersion; # Did you read the comment?
  };
}
