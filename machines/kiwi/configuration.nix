{
  nixos-hardware,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko-config-btrfs.nix
    # ./framework.nix
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # TODO: remove when 6.15.1 hits unstable
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.amdgpu.opencl.enable = true;

  programs.adb.enable = true;
  users.users.pinpox.extraGroups = [ "adbusers" ];

  networking.hostName = "kiwi";

  # Games
  programs.steam.enable = true;
  hardware.xone.enable = true;

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
