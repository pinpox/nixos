{
  nixos-hardware,
  lib,
  ...
}:
{

  imports = [
    ./disko-config-btrfs.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

  networking.hostName = "tanne";

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
