{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.miniflux;
  # Use shared secret from porree (miniflux-oidc generator with share=true)
  oidcSecretPath = config.clan.core.vars.generators."miniflux-oidc".files.client_secret.path;
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

    # Shared OIDC secret (same generator on porree for authelia)
    clan.core.vars.generators."miniflux-oidc" = {
      share = true;
      files.client_secret = { };
      runtimeInputs = with pkgs; [
        coreutils
        openssl
      ];
      script = ''
        mkdir -p $out
        openssl rand -hex 32 > $out/client_secret
      '';
    };

    services.caddy = {
      enable = true;
      virtualHosts."news.0cx.de".extraConfig =
        "reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR}";
    };

    systemd.services.miniflux.serviceConfig.LoadCredential = [
      "oauth2_client_secret_file:${oidcSecretPath}"
    ];

    services.miniflux = {
      enable = true;
      config = {
        OAUTH2_USER_CREATION = "1";
        DISABLE_LOCAL_AUTH = "1";
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR = "127.0.0.1:8787";
        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID = "miniflux";
        OAUTH2_CLIENT_SECRET_FILE = "/run/credentials/miniflux.service/oauth2_client_secret_file";
        OAUTH2_REDIRECT_URL = "https://news.0cx.de/oauth2/oidc/callback";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.pablo.tools";
        OAUTH2_OIDC_PROVIDER_NAME = "pablo.tools";
      };
      adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."credentials".path;
    };

  };
}
