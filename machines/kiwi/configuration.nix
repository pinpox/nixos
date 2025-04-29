{ lib, ... }:
{
  imports = [
    ./disko-config-btrfs.nix
    ./framework.nix
  ];

  networking.hostName = "kiwi";
  pinpox.desktop.enable = true;

  # Games
  programs.steam.enable = true;
  hardware.xone.enable = true;

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
