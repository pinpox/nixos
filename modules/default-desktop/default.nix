{ lib, nur, pkgs, config, flake-self, home-manager, wallpaper-generator, promterm, ... }:
with lib;
let
  cfg = config.pinpox.desktop;
in
{

  imports = [ ../../users/pinpox.nix ];

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

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd start-river";
          user = "greeter";
        };
      };
    };

    # programs.sway.enable = true;

    # Enable networkmanager
    networking.networkmanager.enable = true;

    # DON'T set useGlobalPackages! It's not necessary in newer
    # home-manager versions and does not work with configs using
    # nixpkgs.config`
    home-manager.useUserPackages = true;

    # Pass all flake inputs to home-manager modules aswell so we can use them
    # there.
    # home-manager.extraSpecialArgs = flake-self.inputs;
    home-manager.extraSpecialArgs = {
      inherit wallpaper-generator flake-self nur promterm;

      # Pass system configuration (top-level "config") to home-manager modules,
      # so we can access it's values for conditional statements
      system-config = config;
    };

    nixpkgs.overlays = [
      nur.overlay
      flake-self.overlays.default
      # inputs.neovim-nightly.overlay
    ];

    # TODO parametrize the username
    home-manager.users.pinpox = flake-self.homeConfigurations.desktop;


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
        # home-manager.enable = true;
        # home-manager.configuration = flake-self.homeConfigurations.desktop;
      };

      virtualisation = {
        docker.enable = true;
        virtualbox.enable = true;
      };

      services = {
        xserver.enable = false;
        openssh.enable = true;
        borg-backup.enable = true;
        restic-client = {
          backup-paths-onsite = [ "/home/pinpox/Notes" "/home/pinpox" ];

          backup-paths-exclude = [

            "*.pyc"
            "*/cache2"
            "*/.go/pkg"
            "*/.local/share/Steam"
            "*/.config/chromium"
            "*/.rustup"
            "*/.config/discord"
            "*/.container-diff"
            "*/.gvfs/"
            "*/.local/share/Trash"
            "*/.mozilla/firefox"
            "*/.npm/_cacache"
            "*/.thumbnails"
            "*/.ts3client"
            "*/.vagrant.d"
            "*/.vim"
            "*/.vimtemp"
            "*/Cache"
            "*/Downloads"
            "*/Seafile"
            "*/.nextcloud"

            "/home/pinpox/code"
            # "*/code/nixpkgs"
            # "/home/*/code/**/target/debug"
            # "/home/*/code/github.com/pinpox/nixpkgs"
            # "/home/*/code/github.com/NixOS/nixpkgs"

            "*/VirtualBox VMs"
            "discord/Cache"

            "*/.BurpSuite"
            "*/.cache"
            "*/.cargo"
            "*/.config/Signal"
            "*/.arduino15/packages"
            "*/.platformio"
          ];
        };
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
      # pkgs.nur.repos.mic92.irc-announce

      # borgbackup
      # wezterm-nightly
      acpi
      macchanger
      arandr
      binutils
      file
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
      recursive
      ripgrep
      ruby
      time
      universal-ctags
      wget
      zola
      freecad
      prusa-slicer
    ];

    services.logind.extraConfig = ''
      RuntimeDirectorySize=20G
    '';

    boot = {
      # Use GRUB2 as EFI boot loader.
      loader.grub.useOSProber = true;

      tmp.useTmpfs = false;


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
      package = lib.mkForce pkgs.gnome.gvfs;
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
