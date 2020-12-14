{ config, pkgs, lib, ... }: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
    challengeResponseAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    (builtins.fetchurl { url = "https://github.com/pinpox.keys"; 

          sha256 = "14f7b42fz0159mn1wg9hm0lxi75dkc7gb3bclgm9zhz52yj7fr1y";
  }) ];
}
