{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.wg-client;
in
{

  options.pinpox.wg-client = {
    enable = mkEnableOption "wireguard client configuration";

    serverHostname = mkOption {
      type = types.str;
      default = "porree";
      description = "Hostname of the server (to retrieve pubkey from flake)";
    };

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

    clan.core.vars.generators."wireguard" = {

      files.publickey.secret = false;
      files.privatekey = { };

      runtimeInputs = with pkgs; [ wireguard-tools ];

      script = ''
        wg genkey > $out/privatekey
        wg pubkey < $out/privatekey > $out/publickey
      '';
    };

    networking.wireguard.interfaces = {

      wg0 = {

        ips = [ "${cfg.clientIp}/24" ];

        # Path to the private key file
        privateKeyFile = "${config.clan.core.vars.generators."wireguard".files."privatekey".path}";

        peers = [
          {
            # Public key of the server (not a file path).
            publicKey = (
              builtins.readFile (
                config.clan.core.settings.directory
                + "/vars/per-machine/${cfg.serverHostname}/wireguard/publickey/value"
              )
            );

            # Don't forward all the traffic via VPN, only particular subnets
            allowedIPs = [ "192.168.7.0/24" ];

            # Server IP and port.
            endpoint = "vpn.pablo.tools:51820";

            # Send keepalives every 25 seconds. Important to keep NAT tables
            # alive.
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
