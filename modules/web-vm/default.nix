{ lib, config, ... }:
with lib;
let
  cfg = config.pinpox.services.web-vm;
in
{

  options.pinpox.services.web-vm.enable = mkEnableOption "Web VM";

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      virtualHosts."vm.0cx.de".extraConfig = ''
        root * /var/www/vm-test
        encode zstd gzip
        header Cross-Origin-Embedder-Policy require-corp
        header Cross-Origin-Opener-Policy same-origin
        file_server
      '';
    };
  };
}
