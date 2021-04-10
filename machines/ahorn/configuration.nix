# Configuration file for ahorn
{ self, ... }: {

  imports = [ ./hardware-configuration.nix ];




  pinpox.desktop.homeConfig = {
    imports = [
      ../../home-manager/home.nix
      self.inputs.dotfiles-awesome.nixosModules.dotfiles
      { nixpkgs.overlays = [ self.inputs.nur.overlay self.inputs.neovim-nightly.overlay ]; }
    ];
  };


  boot.blacklistedKernelModules = [ "nouveau" ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };

}
