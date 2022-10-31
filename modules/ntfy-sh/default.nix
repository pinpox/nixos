{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.ntfy-sh;

in
{

  options.pinpox.services.ntfy-sh = {
    enable = mkEnableOption "ntfy-sh notification server";
  };

  config =
    let
      ntfy-port = "8090";
      ntfy-host = "push.pablo.tools";
    in
    mkIf cfg.enable {

      services.ntfy-sh = {
        enable = true;
        settings = {
          behind-proxy = true;
          listen-http = "127.0.0.1:${ntfy-port}";
          base-url = "https://${ntfy-host}";
          auth-file = "/var/lib/ntfy-sh/user.db";
          auth-default-access = "deny-all";
          # https://github.com/binwiederhier/ntfy/issues/459
          web-root = "disable"; # Set to "app" to enable
        };
      };

      users.users.ntfy-sh = {
        home = "/var/lib/ntfy-sh";
        createHome = true;
      };

      # lollypops.secrets.files."nginx/ntfy-sh.passwd" = {
      #   path = "/var/www/ntfy-sh.passwd";
      #   owner = "nginx";
      # };

      services.nginx.virtualHosts."${ntfy-host}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${ntfy-port}";
          # extraConfig = ''
          #   limit_except POST {
          #     auth_basic 'Restricted';
          #     auth_basic_user_file "${config.lollypops.secrets.files."nginx/ntfy-sh.passwd".path}";
          #   }
          # '';
        };
      };
    };
}
