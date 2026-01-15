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
    home-manager.nixosModules.home-manager
  ];

  services.acpid.enable = true;

  # US QWERTY for TTY (mobile devices don't have colemak keyboards)
  console.keyMap = lib.mkForce "us";

  # Enable networkmanager
  networking.networkmanager.enable = true;

  # Often hangs
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  # DON'T set useGlobalPackages! It's not necessary in newer
  # home-manager versions and does not work with configs using
  # nixpkgs.config`
  home-manager.useUserPackages = true;

  # Backup files before overwriting them with home-manager
  home-manager.backupFileExtension = "hm-backup";

  # Pass all flake inputs to home-manager modules aswell so we can use them
  # there.
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
  home-manager.users.pinpox = flake-self.homeConfigurations.mobile;

  # Hardware accelleration
  hardware.graphics = {
    enable = true;
  };

  pinpox = {
    defaults = {
      bluetooth.enable = true;
      environment.enable = true;
      fonts.enable = false; # Disabled - noto-fonts-color-emoji can't cross-compile
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      sound.enable = false;
      zsh.enable = true;
    };

    services = {
      wayland.enable = true;
      openssh.enable = true;
    };
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    gcc
    comma
    acpi
    binutils
    file
    git
    gnumake
    killall
    neovim
    ripgrep
    time
    usbutils
    wget
  ];

  programs.dconf.enable = true;

  # Disable speech-dispatcher to avoid pulling in mbrola-voices (675MB)
  services.speechd.enable = lib.mkForce false;

  # Override fontconfig defaults to avoid noto-fonts-color-emoji
  # which requires Python tools that can't cross-compile
  fonts.fontconfig.defaultFonts.emoji = lib.mkForce [ ];

  # Disable default font packages (includes noto-fonts-color-emoji)
  fonts.enableDefaultPackages = false;

  # Disable modemmanager - cross-compilation is broken
  networking.modemmanager.enable = false;
}
