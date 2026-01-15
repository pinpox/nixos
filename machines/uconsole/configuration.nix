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

  # 32-bit graphics not supported on aarch64
  hardware.graphics.enable32Bit = lib.mkForce false;

  # Filesystems are now managed by disko (see disko-config.nix)

  # Enable NetworkManager for easy WiFi setup
  networking.networkmanager.enable = true;

  # Enable SSH for remote access
  services.openssh.enable = true;
}
