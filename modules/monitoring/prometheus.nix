{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.monitoring-server;
in {

  # https://github.com/NixOS/nixpkgs/issues/126083
  # https://github.com/NixOS/nixpkgs/pull/144984
  options.pinpox.services.monitoring-server = {
    enable = mkEnableOption "monitoring-server setup";

    blackboxTargets = mkOption {
      type = types.listOf types.str;
      default = [ "https://pablo.tools" ];
      example = [ "https://github.com" ];
      description = "Targets to monitor with the blackbox-exporter";
    };

    nodeTargets = mkOption {
      type = types.listOf types.str;
      default = [ "porree.wireguard:9100" ];
      example = [ "hostname.wireguard:9100" ];
      description = "Targets to monitor with the node-exporter";
    };
  };

  config = mkIf cfg.enable {

    systemd.services.prometheus.serviceConfig.EnvironmentFile =
      [ "/var/src/secrets/prometheus/envfile" ];

    services.prometheus = {
      enable = true;
      webExternalUrl = "vpn.prometheus.pablo.tools";

      extraFlags = [ "--log.level=debug" ];
      ruleFiles = [ ./alert-rules.json ];
      # ruleFiles = [ ./alert-rules.yml ];
      # ruleFiles = [
      #   (pkgs.writeText "prometheus-rules.yml" (builtins.toJSON {
      #     groups = [{
      #       name = "alerting-rules";
      #       rules = import ./alert-rules.nix { inherit lib; };
      #     }];
      #   }))
      # ];
      alertmanagers =
        [{ static_configs = [{ targets = [ "localhost:9093" ]; }]; }];

      scrapeConfigs = [

        {
          job_name = "drone";
          bearer_token = "$DRONE_TOKEN";
          static_configs = [{ targets = [ "drone.lounge.rocks" ]; }];
        }
        # {
        #   job_name = "homeassistant";
        #   scrape_interval = "120s";
        #   metrics_path = "/api/prometheus";

        #   # Legacy api password
        #   params.api_password = [ "PASSWORD" ];

        #   # Long-Lived Access Token
        #   bearer_token = "$HASS_TOKEN";
        #   scheme = "https";
        #   static_configs = [{
        #     targets = [ "home.pablo.tools:443" ];
        #   }];
        # }
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
      alertmanager = {
        enable = true;
        # port = 9093; # Default
        webExternalUrl = "https://vpn.alerts.pablo.tools";
        environmentFile = /var/src/secrets/alertmanager/envfile;
        configuration = {
          global = {
            # The smarthost and SMTP sender used for mail notifications.
            # smtp_smarthost = "mail.thalheim.io:587";
            # smtp_from = "alertmanager@thalheim.io";
            # smtp_auth_username = "alertmanager@thalheim.io";
            # smtp_auth_password = "$SMTP_PASSWORD";
          };

          route = {
            receiver = "all";
            routes = [{
              group_by = [ "instance" ];
              group_wait = "30s";
              group_interval = "2m";
              repeat_interval = "2h";
              receiver = "all";
            }];
          };
          receivers = [{
            name = "all";
            webhook_configs = [{
              url = "http://127.0.0.1:8989/webhook";
              # max_alerts = 5;
            }];
          }];
        };
      };
    };
  };
}
