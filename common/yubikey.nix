{ config, pkgs, lib, ... }: {
  programs.ssh.startAgent = false;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gtk2";
    # extraConfig = ''
    #        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry-gnome3
    #      '';
  };

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
}
