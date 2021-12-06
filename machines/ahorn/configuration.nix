# Configuration file for ahorn
{ self, ... }:
{ pkgs, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # services.vault.enable = true;
  # services.vault.extraConfig = ''
  # ui = true
  # '';

  # services.vault.package = pkgs.vault-bin;

  boot.blacklistedKernelModules = [ "nouveau" ];

  age.secrets.secret1.file = "${self.inputs.secrets}/agenix-cli/hosts/kartoffel/some-secret";

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };

  # TODO remove when no longer needed
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
