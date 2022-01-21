{ lib, pkgs, config, ... }:
with lib;

let cfg = config.pinpox.metrics;

in {

  options.pinpox.metrics.fritzbox = {
    enable = mkEnableOption "prometheus fritzbox_exporter metrics collection";

    envfile = mkOption {
      type = types.str;
      default = "/var/src/secrets/fritzbox-exporter/envfile";
      example = "/path/to/envfile";
      description = "EnvironmentFile for fritzbox-exporter";
    };
  };

  config = mkIf cfg.enable {

    # User and group
    users.groups."fritzbox-exporter" = { };
    users.users."fritzbox-exporter" = {
      isSystemUser = true;
      group = "fritzbox-exporter";
    };

    # Service
    systemd.services.fritzbox-exporter = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = [ cfg.envfile ];
        ExecStart = ''
          ${pkgs.fritzbox_exporter}/bin/fritzbox_exporter \
          -password="$FRITZ_PASS" \
          -username="$FRITZ_USER" \
          -nolua=true
        '';
        User = config.users.users.fritzbox-exporter.name;
        Group = config.users.users.fritzbox-exporter.name;
      };
    };

    /* -collect=false: print configured metrics to stdout and exit
       -gateway-luaurl="http://fritz.box": The URL of the FRITZ!Box UI
       -gateway-url="http://fritz.box:49000": The URL of the FRITZ!Box
       -json-out="": store metrics also to JSON file when running test
       -listen-address="127.0.0.1:9042": The address to listen on for HTTPrequests.
       -log-level="info": The logging level. Can be error, warn, info, debug or trace
       -lua-metrics-file="metrics-lua.json": The JSON file with the lua metric definitions.
       -metrics-file="metrics.json": The JSON file with the metric definitions.
       -nolua=false: disable collecting lua metrics
       -password="": The password for the FRITZ!Box UPnP service
       -test=false: print all available metrics to stdout
       -testLua=false: read luaTest.json file make all contained calls anddump results
       -username="": The user for the FRITZ!Box UPnP service
       -verifyTls=false: Verify the tls connection when connecting to the FRITZ!Box
    */

    # Open firewall ports on the wireguard interface
    # networking.firewall.interfaces.wg0.allowedTCPPorts =
    #   lib.optional cfg.blackbox.enable 9115
    #   ++ lib.optional cfg.node.enable 9100;
  };
}
