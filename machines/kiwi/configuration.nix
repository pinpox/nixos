{
  pkgs,
  ...
}:
{

  clan.core.networking.targetHost = "kiwi";

  boot.growPartition = true;
  hardware.enableRedistributableFirmware = true;

  imports = [
    ./disko-config-btrfs.nix
  ];

  # disko.devices.disk.main.imageSize = "40G";
  # disko.imageBuilder.extraDependencies = [ pkgs.kmod ];

  programs.sway.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  pinpox.desktop = {
    enable = true;
    hostname = "kiwi";
  };

  # efiSupport = lib.mkForce false;
  # efiInstallAsRemovable = lib.mkForce false;
  # gfxmodeBios = "1600x900";
  # gfxpayloadBios = "text";

  users.users.pinpox.initialPassword = "changeme";
  boot.loader.efi.canTouchEfiVariables = false;

  # You may also find this setting useful to automatically set the latest compatible kernel:
  # boot.kernelPackages = lib.mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
  # boot.supportedFilesystems.zfs = true;
}
