# Configuration for kartoffel
{ self, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # environment.systemPackages = [self.wezterm];

  pinpox.desktop.homeConfig = {
    imports = [
      ../../home-manager/home.nix
      self.inputs.dotfiles-awesome.nixosModules.dotfiles
      {
        nixpkgs.overlays = [
          self.overlay
          self.inputs.nur.overlay
          self.inputs.neovim-nightly.overlay
        ];
      }
    ];
  };

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.3";
    hostname = "kartoffel";
    bootDevice = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
  };

  # Video driver for nvidia graphics card
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];


  hardware.sane.enable = true;
    users.users.pinpox.extraGroups = [ "scanner" "lp" ];

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

}
