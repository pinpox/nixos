{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.owncast;
in
{
  options.pinpox.services.owncast = {
    enable = mkEnableOption "owncast server";
    host = mkOption {
      type = types.str;
      default = "stream.0cx.de";
      description = "Host serving owncast";
      example = "stream.0cx.de";
    };
  };

  config = mkIf cfg.enable {

    services.owncast = {
      enable = true;
      port = 9768;
      rtmp-port = 1935;
    };

    networking.firewall.allowedTCPPorts = [ config.services.owncast.rtmp-port ];

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host
      }".extraConfig = "reverse_proxy 127.0.0.1:${builtins.toString config.services.owncast.port}";
    };
  };
}
