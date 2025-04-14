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

      # From Gitea
      prompts.oauth2_client_id.persist = true;
      prompts.oauth2_client_secret.persist = true;

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];

      script = # sh
        ''
          mkdir -p $out
          printf "ADMIN_USERNAME=admin\nADMIN_PASSWORD='%s'" "$(xkcdpass -d-)" > $out/credentials
        '';
    };

    services.caddy = {
      enable = true;
      virtualHosts."news.0cx.de".extraConfig =
        "reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR}";
    };

    systemd.services.miniflux.serviceConfig.LoadCredential =
      with config.clan.core.vars.generators."miniflux".files; [
        "oauth2_client_id_file:${oauth2_client_id.path}"
        "oauth2_client_secret_file:${oauth2_client_secret.path}"
      ];

    services.miniflux = {
      enable = true;
      config = {
        # OAUTH2_USER_CREATION = "1";
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR = "127.0.0.1:8787";
        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID_FILE = "%d/oauth2_client_id_file";
        OAUTH2_CLIENT_SECRET_FILE = "%d/oauth2_client_secret_file";
        OAUTH2_REDIRECT_URL = "https://news.0cx.de/oauth2/oidc/callback";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://git.0cx.de/";
      };
      adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."credentials".path;
    };
  };
}
