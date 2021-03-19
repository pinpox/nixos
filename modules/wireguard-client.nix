{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.wg-client;
in {

  options.pinpox.wg-client = {
    enable = mkEnableOption "hello service";
    clientIp = mkOption {
      type = types.str;
      default = "0.0.0.0";
      example = "192.168.7.1/24";
      description = ''
        IP address of the host.
        Make sure to also set the peer entry for the server accordingly.
      '';
    };
  };

  config = mkIf cfg.enable {

    networking.wireguard.interfaces = {

      wg0 = {

        ips = [ "${cfg.clientIp}/24" ];

        # Path to the private key file
        privateKeyFile = "/var/src/secrets/wireguard/private";
        peers = [{
          # Public key of the server (not a file path).
          publicKey = "XKqEk5Hsp3SRVPrhWD2eLFTVEYb9NYRky6AermPG8hU=";

          # Don't forward all the traffic via VPN, only particular subnets
          allowedIPs = [ "192.168.7.0/24" ];

          # Server IP and port.
          endpoint = "vpn.pablo.tools:51820";

          # Send keepalives every 25 seconds. Important to keep NAT tables
          # alive.
          persistentKeepalive = 25;
        }];
      };
    };
  };
}
