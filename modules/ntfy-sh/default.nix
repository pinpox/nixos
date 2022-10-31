{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.ntfy-sh;

in
{

  options.pinpox.services.ntfy-sh = {
    enable = mkEnableOption "ntfy-sh notification server";
  };

  config = mkIf cfg.enable {

    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = "127.0.0.1:8090";
        base-url = "https://push.pablo.tools";
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";
      };
    };

    users.users.ntfy-sh = {
      home = "/var/lib/ntfy-sh";
      createHome = true;
    };

    # TODO Reverse proxy
  };
}
