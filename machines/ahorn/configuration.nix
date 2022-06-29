# Configuration file for ahorn
{ options, ... }: {

  imports = [
    ./hardware-configuration.nix
    ./retiolum.nix
  ];

  lollypops.secrets.files = {
    secret1 = {
      cmd = "pass test-password";
      path = "/tmp/testfile5";
    };
  };

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.retiolum.ipv4 = "10.243.100.100";
  networking.retiolum.ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";

  lollypops.secrets.files = {
    "retiolum/rsa_priv" = { };
    "retiolum/ed25519_priv" = { };
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "${config.lollypops.secrets.files."retiolum/rsa_priv".path}";
    ed25519PrivateKeyFile = "${config.lollypops.secrets.files."retiolum/ed25519_priv".path}";
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  pinpox.services.restic-client.enable = true;

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };
}
