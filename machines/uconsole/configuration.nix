{
  nixos-hardware,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.clockworkpi-uconsole-cm4
    ./disko-config.nix
  ];

  # uConsole uses a Raspberry Pi CM4 (aarch64)
  nixpkgs.hostPlatform = "aarch64-linux";

  networking.hostName = "uconsole";

  # Disable grub - we use extlinux from the rpi4 module
  boot.loader.grub.enable = lib.mkForce false;

  # Additional initrd modules for early display (LUKS prompt)
  boot.initrd.kernelModules = [
    "drm"
    "drm_kms_helper"
    "vc4"
    "panel_cwu50"
    "ocp8178_bl"
    "pwm_bcm2835"
    "i2c_bcm2835"
    "i2c_dev"
  ];

  # Console configuration for boot
  boot.kernelParams = [
    "console=tty1"
    "fbcon=rotate:1"  # uConsole display is rotated 90 degrees
    "loglevel=4"
  ];

  # Add modules needed in initrd
  boot.initrd.availableKernelModules = [
    # USB ethernet adapters
    "usbnet"
    "ax88179_178a"
    "cdc_ether"
    "r8152"
  ];

  # Enable Mesa GPU drivers for Wayland/graphics support
  hardware.graphics.enable = true;
  # 32-bit graphics not supported on aarch64
  hardware.graphics.enable32Bit = lib.mkForce false;

  # Console font sized for the 5" 720x1280 display
  console = {
    earlySetup = true;
    font = "ter-v24n";
    packages = with pkgs; [ terminus_font ];
  };

  # Filesystems are now managed by disko (see disko-config.nix)

  # Enable NetworkManager for easy WiFi setup
  networking.networkmanager.enable = true;

  # Pre-configure WiFi for debugging (password in plain text - change later)
  networking.networkmanager.ensureProfiles.profiles = {
    "virus.exe" = {
      connection = {
        id = "virus.exe";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        ssid = "virus.exe";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "gerolsteiner";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        method = "auto";
      };
    };
  };

  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Set initial root password for debugging (change after first login!)
  users.users.root.initialPassword = "nixos";
}
