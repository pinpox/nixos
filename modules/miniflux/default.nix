{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.miniflux;
in
{

  options.pinpox.services.miniflux = {
    enable = mkEnableOption "miniflux RSS reader";
  };

  config = mkIf cfg.enable {

    clan.core.vars.generators."miniflux" = {
      files.credentials = { };

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];

      script = ''
        mkdir -p $out
        printf "ADMIN_USERNAME=admin\nADMIN_PASSWORD='%s'" "$(xkcdpass -d-)" > $out/credentials
      '';
    };

    services.caddy = {
      enable = true;
      virtualHosts."news.0cx.de".extraConfig =
        "reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR}";
    };

    services.miniflux = {
      enable = true;
      config = {
        OAUTH2_USER_CREATION = "1";
        DISABLE_LOCAL_AUTH = "1";
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR = "127.0.0.1:8787";
        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID = "miniflux";
        OAUTH2_REDIRECT_URL = "https://news.0cx.de/oauth2/oidc/callback";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.pablo.tools";
        OAUTH2_OIDC_PROVIDER_NAME = "pablo.tools";
      };
      adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."credentials".path;
    };

  };
}
