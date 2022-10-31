{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.monitoring-server.dashboard;
in
{



  # [porree:rebuild] trace: warning: Provisioning Grafana datasources with options has been deprecated.
  # [porree:rebuild] Use `services.grafana.provision.datasources.settings` or
  # [porree:rebuild] `services.grafana.provision.datasources.path` instead.

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
    lollypops.secrets.files."grafana/smtp-password" = {
      owner = "grafana";
      path = "/var/lib/grafana/smtp-password";
    };

    # Graphana fronend
    services.grafana = {
      enable = true;

      settings = {
        server = {
          domain = cfg.domain;
          # Default is 3000
          http_port = 9005;
          http_addr = "127.0.0.1";
        };

        # Mail notifications
        smtp = {
          enabled = true;
          host = "smtp.sendgrid.net:587";
          user = "apikey";
          passwordFile = "${config.lollypops.secrets.files."grafana/smtp-password".path}";
          fromAddress = "status@pablo.tools";
        };
      };


      # TODO add plugins here, instead of using grafana-cli
      # declarativePlugins = with pkgs.grafanaPlugins [
      #    grafana-piechart-panel
      # ];
      # TODO provision the dashboards as currently configured

      provision.datasources.settings =
        {
          datasources =
            [
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
  };
}
