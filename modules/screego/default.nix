{ config, lib, ... }:
let
  cfg = config.pinpox.services.screego;
in
{
  options.pinpox.services.screego = {
    enable = lib.mkEnableOption "screego server";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "0cx.de";
      description = "Domain to create the sudomains unders";
    };

  };

  config = lib.mkIf cfg.enable {

    services.caddy = {
      enable = true;
      virtualHosts = {
        "screen.${cfg.domain}".extraConfig = "reverse_proxy 127.0.0.1:5050";
        "turn.${cfg.domain}".extraConfig = "reverse_proxy 127.0.0.1:5050";
      };
    };

    lollypops.secrets.files."screego/users" = { };
    lollypops.secrets.files."screego/env" = { };

    systemd.services.screego.serviceConfig.LoadCredential = [
      "users:${config.lollypops.secrets.files."screego/users".path}"
    ];

    services.screego = {
      enable = true;
      openFirewall = true;
      environmentFile = "${config.lollypops.secrets.files."screego/env".path}";
      settings = {
        # SCREEGO_EXTERNAL_IP = "46.38.242.17";
        SCREEGO_EXTERNAL_IP = "dns:screen.${cfg.domain}";
        SCREEGO_SERVER_TLS = "false";
        SCREEGO_CORS_ALLOWED_ORIGINS = "https://screen.${cfg.domain}";
        SCREEGO_USERS_FILE = "%d/users";
        SCREEGO_PROMETHEUS = "true";
      };
    };
  };
}
