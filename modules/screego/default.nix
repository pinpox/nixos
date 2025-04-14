{
  config,
  lib,
  pkgs,
  ...
}:
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

    clan.core.vars.generators."screego" = {

      files.envfile = { };
      files.users = { };
      files.prometheus-pass = { };

      runtimeInputs = with pkgs; [
        coreutils
        screego
        xkcdpass
      ];

      script = ''
        echo "SCREEGO_SECRET=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 40)" > $out/envfile
        xkcdpass -n 4 -d - > $out/prometheus-pass
        cat $out/prometheus-pass | screego hash --name "prometheus" --pass - > $out/users
      '';
    };

    systemd.services.screego.serviceConfig.LoadCredential = [
      "users:${config.clan.core.vars.generators.screego.files."users".path}"
    ];

    services.screego = {
      enable = true;
      openFirewall = true;
      environmentFile = "${config.clan.core.vars.generators.screego.files."envfile".path}";
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
