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

  # Additional kernel params (display params are in nixos-hardware)
  boot.kernelParams = [
    "console=tty1"
    "loglevel=4"
  ];

  # Additional modules available in initrd (not forced to load)
  # Display modules are now in nixos-hardware
  boot.initrd.availableKernelModules = [
    # USB ethernet adapters (for network debugging)
    "usbnet"
    "ax88179_178a"
    "cdc_ether"
    "r8152"
    # LUKS/dm-crypt support
    "dm_crypt"
    "dm_mod"
    # Crypto modules for xchacha20,aes-adiantum cipher (fast on ARM without AES-NI)
    "xchacha20"
    "adiantum"
    "nhpoly1305"
    "chacha_generic"
    "chacha_neon"
    "aes_generic"
    "aes_arm64"
    "sha256_generic"
    "sha256_arm64"
    "algif_skcipher"
  ];

  # 32-bit graphics not supported on aarch64
  hardware.graphics.enable32Bit = lib.mkForce false;

  # Console font sized for the 5" 720x1280 display
  console = {
    font = "ter-v24n";
    packages = with pkgs; [ terminus_font ];
  };

  # Filesystems are now managed by disko (see disko-config.nix)

  # Enable NetworkManager for easy WiFi setup
  networking.networkmanager.enable = true;

  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Set initial root password for debugging (change after first login!)
  users.users.root.initialPassword = "nixos";
}
