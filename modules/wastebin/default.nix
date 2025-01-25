{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.wastebin;
in
{

  options.pinpox.services.wastebin.enable = mkEnableOption "wastebin server";

  config = mkIf cfg.enable {

    clan.core.vars.generators."wastebin" = {
      files.envfile = { };
      runtimeInputs = [ pkgs.coreutils ];
      script = ''
        echo "WASTEBIN_PASSWORD_SALT=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 80)" >> $out/envfile
        echo "WASTEBIN_SIGNING_KEY=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 80)" >> $out/envfile
      '';
    };

    # Create system user and group
    services.wastebin = {
      enable = true;

      secretFile = config.clan.core.vars.generators."wastebin".files."envfile".path;

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
    services.caddy.virtualHosts."paste.0cx.de".extraConfig =
      "reverse_proxy ${config.services.wastebin.settings.WASTEBIN_ADDRESS_PORT}";
  };
}
