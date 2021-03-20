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
      listenAddress = config.pinpox.wg-client.clientIp;
      enabledCollectors = [ "systemd" ];
    };

    # Open wirewall port for the wireguard interface
    networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 ];
  };
}
