{ pkgs, lib, ... }:
with lib; {
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.ssh.startAgent = false;

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      challengeResponseAuthentication = false;
    };

    users = {
      users.root = {
        password = "root"; # Change me!
        openssh.authorizedKeys.keyFiles =
          [ (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "colemak";
    };
  };
}
