{ lib, pkgs, config, inputs, ... }:
with lib;
let cfg = config.pinpox.services.home-assistant-grafana-relay;
in {

  options.pinpox.services.home-assistant-grafana-relay = {
    enable = mkEnableOption "home-assistant-grafana-relay service";

    listenHost = mkOption {
      type = types.str;
      default = "localhost";
      example = "127.0.0.1";
      description = "Host to listen on";
    };

    listenPort = mkOption {
      type = types.str;
      default = "12000";
      example = "1300";
      description = "Port to listen on";
    };

    haUri = mkOption {
      type = types.str;
      default = null;
      example = "http://home.domain.tld/api/services/notify/notify";
      description = "Port to listen on";
    };

    envFile = mkOption {
      type = types.str;
      default = null;
      example = "/var/secrets/ha-envfile";
      description = ''
        Additional environment file to pass to the service.
        e.g. containing the long-lived access token as:
        AUTH_TOKEN="LONG_LIVED_ACCESS_TOKEN"
      '';
    };
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.ha-relay = {
      isSystemUser = true;
      description = "ha-relay system user";
      extraGroups = [ "ha-relay" ];
     group = "ha-relay";
    };

    users.groups.ha-relay = { name = "ha-relay"; };

    # Service
    systemd.services.ha-relay = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start ha-relay";
      serviceConfig = {

        EnvironmentFile = [ cfg.envFile ];
        Environment = [
          "HM_SERVICE_URI='${cfg.haUri}'"
          "LISTEN_PORT='${cfg.listenPort}'"
          "LISTEN_HOST='${cfg.listenHost}'"
        ];

        User = "ha-relay";
        ExecStart = "${inputs.ha-relay.packages."${config.nixpkgs.system}".ha-relay}/bin/home-assistant-grafana-relay";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

  };
}
