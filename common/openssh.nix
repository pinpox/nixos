{ config, pkgs, lib, ... }: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
    challengeResponseAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
}
