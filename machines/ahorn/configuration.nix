# Configuration file for ahorn
{ config, pkgs, inputs, ... }:
{

  imports = [ ./hardware-configuration.nix ];

              boot.blacklistedKernelModules = [ "nouveau" ];

              pinpox.desktop = {
                enable = true;
                wireguardIp = "192.168.7.2";
                hostname = "ahorn";
                bootDevice =
                  "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
              };

}
