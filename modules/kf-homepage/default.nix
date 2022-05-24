{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.kf-homepage;

in
{

  options.pinpox.services.kf-homepage = {
    enable = mkEnableOption "Krosse Flagge Homepage";
  };

  config = mkIf cfg.enable {

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        "0cx.de" = {
          forceSSL = true;
          enableACME = true;
          root = ./page;
        };
      };
    };
  };
}
