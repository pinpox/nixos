{
  nixos-hardware,
  lib,
  ...
}:
{

  imports = [
    ./disko-config-btrfs.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-t490
  ];

  networking.hostName = "fichte";

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
