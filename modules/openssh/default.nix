{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.openssh;
in {

  options.pinpox.services.openssh = {
    enable = mkEnableOption "OpenSSH server";
  };

  config = mkIf cfg.enable {

    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      kbdInteractiveAuthentication = false;
    };

    # Block anything that is not HTTP(s) or SSH.
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 22 ];
    };

    users.users.root.openssh.authorizedKeys.keyFiles = [
      ( pkgs.fetchurl {
        url = "https://github.com/pinpox.keys";
        sha256 = "sha256-Cf/PSZemROU/Y0EEnr6A+FXE0M3+Kso5VqJgomGST/U=";
      })
    ];
  };
}
