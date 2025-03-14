# Configuration for kartoffel
{ pkgs, ... }:
{

  imports = [ ./hardware-configuration.nix ];

  clan.core.networking.targetHost = "kartoffel";

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.3";
    hostname = "kartoffel";
  };

  # Encrypted drive to be mounted by the bootloader. Path of the device will
  # have to be changed for each install.
  boot.initrd.luks.devices = {
    root = {
      # Get UUID from blkid /dev/sda2
      device = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
      preLVM = true;
      allowDiscards = true;
    };
  };

  # pinpox.defaults.CISkip = true;

  # Video driver for nvidia graphics card
  hardware.nvidia.open = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

}
