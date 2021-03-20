{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.metrics.node;
in {

  options.pinpox.metrics.node = {
    enable = mkEnableOption "node-exporter metrics export";
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = pinpox.wg-client.clientIP;
      networking.firefall.interfaces.wg0.allowedTCPPorts = [ 9100 ];
    };
  };
}
