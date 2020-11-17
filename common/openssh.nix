{ config, pkgs, lib, ... }: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
    challengeResponseAuthentication = false;
  };
}
