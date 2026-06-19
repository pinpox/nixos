{
  pkgs,
  nixos-hardware,
  ...
}:
{

  networking.hostName = "limette";

  pinpox.defaults.lvm-grub.enable = true;
  boot.growPartition = true;

  hardware.enableRedistributableFirmware = true;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    ./disko-config-btrfs.nix
  ];

  disko.imageBuilder.extraDependencies = [ pkgs.kmod ];

  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver
  ];

  # Intel Gen GPU: pin the media driver explicitly. This used to live as a
  # global session var in modules/wayland, which wrongly forced iHD on AMD
  # machines (radeonsi) and broke their VA-API. Auto-detection handles AMD;
  # only Intel needs the override.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  boot.loader.efi.canTouchEfiVariables = false;
}
