{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.miniflux;

in
{

  options.pinpox.services.miniflux = {
    enable = mkEnableOption "miniflux RSS reader";
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files = {
      "miniflux/credentials" = { };
      "miniflux/oauth2_client_id_file" = { };
      "miniflux/oauth2_client_secret_file" = { };
    };

    services.caddy = {
      enable = true;
      virtualHosts."news.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:8787";
    };

    systemd.services.miniflux = {
      serviceConfig = {
        LoadCredential = [
          "oauth2_client_id_file:${config.lollypops.secrets.files."miniflux/oauth2_client_id_file".path}"
          "oauth2_client_secret_file:${config.lollypops.secrets.files."miniflux/oauth2_client_secret_file".path}"
        ];
      };
    };

    services.miniflux = {
      enable = true;
      config = {
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR = "127.0.0.1:8787";
        OAUTH2_PROVIDER = "oidc";

        # See: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
        # In order to reference the path a credential may be read from within a
        # ExecStart= command line use "${CREDENTIALS_DIRECTORY}/mycred", e.g.
        # "ExecStart=cat ${CREDENTIALS_DIRECTORY}/mycred". In order to reference the
        # path a credential may be read from within a Environment= line use
        # "%d/mycred", e.g. "Environment=MYCREDPATH=%d/mycred".

        OAUTH2_CLIENT_ID_FILE = "%d/oauth2_client_id_file";
        OAUTH2_CLIENT_SECRET_FILE = "%d/oauth2_client_secret_file";

        OAUTH2_REDIRECT_URL = "https://news.0cx.de/oauth2/oidc/callback";
        # OAUTH2_USER_CREATION = "1";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://git.0cx.de/";
      };
      adminCredentialsFile = config.lollypops.secrets.files."miniflux/credentials".path;

    };
  };
}
