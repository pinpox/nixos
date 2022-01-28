# Configuration file for ahorn
{ self, ... }:
{ pkgs, ... }: {

  imports = [ ./hardware-configuration.nix ./retiolum.nix ];

  networking.retiolum.ipv4 = "10.243.100.100";
  networking.retiolum.ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "/var/src/secrets/retiolum/rsa_priv";
    ed25519PrivateKeyFile = "/var/src/secrets/retiolum/ed25519_priv";
  };
  # services.vault.enable = true;
  # services.vault.extraConfig = ''
  # ui = true
  # '';

  # services.vault.package = pkgs.vault-bin;

  boot.blacklistedKernelModules = [ "nouveau" ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };

  # TODO remove when no longer needed
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
