{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.monitoring-server;
in {

  options.pinpox.services.monitoring-server = {
    enable = mkEnableOption "monitoring-server setup";
    blackboxTargets = mkOption {
      type = types.listOf types.str;
      default = [ "https://pablo.tools"];
      example = [ "https://github.com" ];
      description = "Targets to monitor with the blackbox-exporter";
    };
    nodeTargets = mkOption {
      type = types.listOf types.str;
      default = [ "porree.wireguard:9100"];
      example = [ "hostname.wireguard:9100" ];
      description = "Targets to monitor with the node-exporter";
    };
  };

  config = mkIf cfg.enable {
    # Graphana fronend
    services.grafana = {
      enable = true;
      domain = "status.pablo.tools";
      # Default is 3000
      port = 9005;
      addr = "127.0.0.1";

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

    services.prometheus = {
      enable = true;

      scrapeConfigs = [
        {
          job_name = "blackbox";
          metrics_path = "/probe";
          params = { module = [ "http_2xx" ]; };
          static_configs = [{ targets = cfg.blackboxTargets; }];

          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement =
                "127.0.0.1:9115"; # The blackbox exporter's real hostname:port.
            }
          ];
        }
        {
          job_name = "node-stats";
          static_configs = [{ targets = cfg.nodeTargets; }];
        }
      ];
    };
  };

}
