# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];

  # Needed for ZFS
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "887bde8c";

  # Efi partition (SSD)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E45C-8185";
    fsType = "vfat";
  };

  # Root drive (SSD)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/74866c52-5077-44aa-afb2-88ce9e72ab47";
    fsType = "ext4";
  };

  # Swap partition
  swapDevices =
    [{ device = "/dev/disk/by-uuid/8551b399-6866-40e0-b8f5-266b5475ffa9"; }];

  # Data drive for seafile
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/426645bc-dbf6-4c4d-b389-16bbb55d7a14";
    fsType = "ext4";
  };

  # Backup drive for borgbackup
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/9961fd1b-3162-474d-9e2e-7cb7d269cd0e";
    fsType = "ext4";
  };

  fileSystems."/mnt/backup-old" = {
    device = "/dev/disk/by-uuid/a6a101de-0238-4b87-ada2-76653ce51cfc";
    fsType = "ext4";
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
