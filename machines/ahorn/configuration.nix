# Configuration file for ahorn
{ self, ... }: {

  imports = [ ./hardware-configuration.nix ];

  pinpox.desktop.homeConfig = self.inputs.nixos-home.nixosModules.desktop;

  boot.blacklistedKernelModules = [ "nouveau" ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };

}
