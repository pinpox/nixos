{ config, pkgs, lib, pinpox-keys, ... }:
with lib;
let cfg = config.pinpox.services.openssh;
in
{

  options.pinpox.services.openssh = {
    enable = mkEnableOption "OpenSSH server";
  };

  config = mkIf cfg.enable {

    _module.args.pinpox-keys = pinpox-keys;

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
      pinpox-keys
    ];
  };
}
