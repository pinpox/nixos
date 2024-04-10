{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.wastebin;
in
{

  options.pinpox.services.wastebin = {
    enable = mkEnableOption "wastebin server";
  };

  config = mkIf cfg.enable {

    # WASTEBIN_PASSWORD_SALT
    # WASTEBIN_SIGNING_KEY
    lollypops.secrets.files."wastebin/envfile" = { };

    # Create system user and group
    services.wastebin = {
      enable = true;

      secretFile = config.lollypops.secrets.files."wastebin/envfile".path;

      settings = {
        WASTEBIN_ADDRESS_PORT = "127.0.0.1:8088";
        WASTEBIN_BASE_URL = "https://paste.0cx.de";
        WASTEBIN_HTTP_TIMEOUT = 7;
        WASTEBIN_MAX_BODY_SIZE = 1024;
        WASTEBIN_TITLE = "wastebin";
        RUST_LOG = "warning";
      };
    };

    # Reverse proxy
    services.caddy = {
      enable = true;
      virtualHosts = {
        "paste.0cx.de".extraConfig = "reverse_proxy ${config.services.wastebin.settings.WASTEBIN_ADDRESS_PORT}";
      };
    };
  };
}
