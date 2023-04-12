{ lib, config, ... }:
with lib;
let cfg = config.pinpox.services.kf-homepage;
in
{

  options.pinpox.services.kf-homepage = {
    enable = mkEnableOption "Krosse Flagge Homepage";
  };

  config = mkIf cfg.enable {

    services.caddy = {
      enable = true;
      virtualHosts = {
        "0cx.de".extraConfig = ''
          encode gzip
          root * ${./page}
        '';
      };
    };
  };
}
