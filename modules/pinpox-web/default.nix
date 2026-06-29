{ lib, config, ... }:
with lib;
let
  cfg = config.pinpox.services.pinpox-web;
in
{

  options.pinpox.services.pinpox-web.enable = mkEnableOption "Pinpox homepage";

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      virtualHosts = {
        "pinpox.com".extraConfig = ''
          root * ${./page}
          encode zstd gzip
          file_server
        '';
      };
    };
  };
}
