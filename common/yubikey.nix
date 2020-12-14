{ config, pkgs, lib, ... }: {
  programs.ssh.startAgent = false;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gtk2";
  };

  # Needed for yubikey to work
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
}
