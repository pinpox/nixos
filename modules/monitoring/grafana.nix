{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.monitoring-server.dashboard;
in {

  options.pinpox.services.monitoring-server.dashboard = {
    enable = mkEnableOption "Grafana dashboard";

    domain = mkOption {
      type = types.str;
      default = "status.pablo.tools";
      example = "dashboards.myhost.com";
      description = "Domain for grafana";
    };
  };

  config = mkIf cfg.enable {

    # SMTP password file
    users.users.grafana = { extraGroups = [ "keys" ]; };
    krops.secrets.files = {
      grafana-smtp-pass = {
        owner = "grafana";
        source-path = "/var/src/secrets/grafana/smtp-password";
      };
    };

    # Graphana fronend
    services.grafana = {
      enable = true;
      domain = cfg.domain;
      # Default is 3000
      port = 9005;
      addr = "127.0.0.1";

      # Mail notifications
      smtp = {
        enable = true;
        host = "smtp.sendgrid.net:587";
        user = "apikey";
        passwordFile = "/run/keys/grafana-smtp-pass";
        fromAddress = "status@pablo.tools";
      };

      # TODO add plugins here, instead of using grafana-cli
      # declarativePlugins = with pkgs.grafanaPlugins [
      #    grafana-piechart-panel
      # ];
      # TODO provision the dashboards as currently configured

      provision.datasources = [
        {
          name = "Prometheus localhost";
          url = "http://localhost:9090";
          type = "prometheus";
          isDefault = true;
        }
        {
          name = "loki";
          url = "http://localhost:3100";
          type = "loki";
        }
      ];
    };
  };
}
