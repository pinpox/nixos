{
  config,
  pkgs,
  lib,
  nur,
  flake-self,
  wallpaper-generator,
  promterm,
  home-manager,
  ...
}:
{

  imports = [
    ../../users/pinpox.nix
    ./nextcloud-desktop.nix
    home-manager.nixosModules.home-manager
  ];

  services.fwupd.enable = true;
  services.acpid.enable = true;

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Enable networkmanager
  networking.networkmanager.enable = true;

  # Often hangs
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  hardware.keyboard.qmk.enable = true;

  services.udev.packages = [
    pkgs.via
    pkgs.qmk-udev-rules # For QMK/Via
    pkgs.libsigrok # For pulseview
  ];

  # DON'T set useGlobalPackages! It's not necessary in newer
  # home-manager versions and does not work with configs using
  # nixpkgs.config`
  home-manager.useUserPackages = true;

  # Backup files before overwriting them with home-manager
  home-manager.backupFileExtension = "hm-backup";

  # Pass all flake inputs to home-manager modules aswell so we can use them
  # there.
  # home-manager.extraSpecialArgs = flake-self.inputs;
  home-manager.extraSpecialArgs = {
    inherit
      wallpaper-generator
      flake-self
      nur
      promterm
      ;

    # Pass system configuration (top-level "config") to home-manager modules,
    # so we can access it's values for conditional statements. Writing is NOT possible!
    system-config = config;
  };

  nixpkgs.overlays = [
    nur.overlays.default
    flake-self.overlays.default
  ];

  # TODO parametrize the username
  home-manager.users.pinpox = flake-self.homeConfigurations.desktop;

  # Hardware accelleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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
      # home-manager.enable = true;
      # home-manager.configuration = flake-self.homeConfigurations.desktop;
    };

    virtualisation = {
      docker.enable = true;
      virt-manager.enable = true;
      virtualbox.enable = false;
    };

    services = {

      unbound-desktop.enable = false;

      wayland.enable = true;
      openssh.enable = true;

      restic-client = {
        enable = true;
        backup-paths-onsite = [
          "/home/pinpox/Notes"
          "/home/pinpox"
          "/home/pinpox/.mozilla/firefox/pinpox/places.sqlite"
          # "*/.local/share/password-store"
          # "*/.passage"
          # "*/.gnupg"
          # "*/.ssh"
        ];
        backup-paths-offsite = [
          "/home/pinpox/.mozilla/firefox/pinpox/places.sqlite"
          "/home/pinpox/Notes"
          "/home/pinpox"
        ];

      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # irc-announce irc.hackint.org 6697 testbot992 '#lounge-rocks2' 1 "test2"
    # pkgs.nur.repos.mic92.irc-announce

    firefox

    gcc
    comma
    acpi
    arandr
    binutils
    file
    git
    gnumake
    killall
    lm_sensors
    neovim
    nixpkgs-review
    nix-init
    nix-update
    nodejs
    ripgrep
    time
    usbutils
    wget
  ];

  services.logind.settings.Login.RuntimeDirectorySize = "20G";

  boot = {
    # Use GRUB2 as EFI boot loader.
    loader.grub.useOSProber = true;
    tmp.useTmpfs = false;
  };

  programs.dconf.enable = true;

  # For user-space mounting things like smb:// and ssh:// in thunar etc. Dbus
  # is required.
  services.gvfs = {
    enable = true;
    # Default package does not support all protocols. Use the full-featured
    # gnome version
    package = lib.mkForce pkgs.gnome.gvfs;
  };
}
