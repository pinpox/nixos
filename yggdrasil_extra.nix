{ lib, config, ... }:
{

  networking.firewall = lib.optionalAttrs (config.networking.hostName == "porree") {
    allowedTCPPorts = [ 6443 ];
    allowedUDPPorts = [ 6443 ];
  };

  services.yggdrasil.settings.Listen = lib.optionals (config.networking.hostName == "porree") [
    "quic://[::]:6443"
    "tls://[::]:6443"
    "ws://[::1]:6444"
    # "tcp://[::1]:6444"

    "quic://94.16.108.229:6443"
    "tls://94.16.108.229:6443"
    "ws://94.16.108.229:6443"
    # "tcp://94.16.108.229:6443"
  ];
}
