{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.calibre-web;
in
{

  options.pinpox.services.calibre-web = {
    enable = mkEnableOption "calibre-web config";
    host = mkOption {
      type = types.str;
      default = "books.0cx.de";
      description = "Host serving calibre";
      example = "books.0cx.de";
    };
  };

  config = mkIf cfg.enable {

    services.calibre-web = {

      enable = true;

      # listen.port = 8083
      listen.ip = "127.0.0.1";

      options.enableBookUploading = true;
      # options.reverseProxyAuth.header
      # options.reverseProxyAuth.enable
      # options.enableKepubify
      # options.enableBookConversion
      # options.calibreLibrary
    };

    # Reverse proxy
    services.caddy.virtualHosts."${cfg.host}".extraConfig =
      with config.services.calibre-web.listen;
      "reverse_proxy ${ip}:${builtins.toString port}";

    # Backups
    pinpox.services.restic-client.backup-paths-offsite = [ config.services.calibre-web.dataDir ];

  };
}
