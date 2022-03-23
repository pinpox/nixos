{ lib, nur, dotfiles-awesome, pkgs, config, flake-self, home-manager, ... }:
with lib;
let cfg = config.pinpox.desktop;
in {

  imports = [ ../../users/pinpox.nix home-manager.nixosModules.home-manager ];

  options.pinpox.desktop = {

    enable = mkEnableOption "the default desktop configuration";

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
      description = ''
        Path of the underlying luks-encrypted root.
        Get UUID from e.g.
        blkid /dev/sda2'';
      example = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
    };
  };

  config = mkIf cfg.enable {

    # DON'T set useGlobalPackages! It's not necessary in newer
    # home-manager versions and does not work with configs using
    # nixpkgs.config`
    home-manager.useUserPackages = true;

    nixpkgs.overlays = [ nur.overlay ];

    home-manager.users.pinpox = {

      imports = [
        ../../home-manager/home.nix
        dotfiles-awesome.nixosModules.dotfiles
        {
          nixpkgs.overlays = [
            flake-self.overlays.default
            nur.overlay
            # inputs.neovim-nightly.overlay 
          ];
        }
      ];
    };

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
        borg-backup.enable = true;
      };

      metrics.node.enable = true;

      wg-client = {
        enable = true;
        clientIp = cfg.wireguardIp;
      };
    };

    # Don' backup docker stuff on desktops
    services.borgbackup.jobs.box-backup.exclude = [ "/var/lib/docker" ];

    # here goes the configuration, reference values with cfg.varname
    # e.g. networking.wireguard.interfaces = { };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [

      # irc-announce irc.hackint.org 6697 testbot992 '#lounge-rocks2' 1 "test2"
      pkgs.nur.repos.mic92.irc-announce

      # borgbackup
      # wezterm-nightly
      arandr
      binutils
      git
      gnumake
      go
      jetbrains-mono
      killall
      lm_sensors
      neovim
      nixfmt
      nodejs
      openvpn
      python
      recursive
      ripgrep
      ruby
      time
      universal-ctags
      wget
      zola
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

    # For user-space mounting things like smb:// and ssh:// in thunar etc. Dbus
    # is required.
    services.gvfs = {
      enable = true;
      # Default package does not support all protocols. Use the full-featured
      # gnome version
      package = lib.mkForce pkgs.gnome3.gvfs;
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = cfg.stateVersion; # Did you read the comment?
  };
}
