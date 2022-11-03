{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.monitoring-server;
in
{

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

    jsonTargets = mkOption {
      type = types.listOf types.str;
      # default = [ "https://pablo.tools" ];
      example = [ "http://birne.wireguard/borg-ahorn.json" ];
      description = "Targets to probe with the json-exporter";
    };

    nodeTargets = mkOption {
      type = types.listOf types.str;
      default = [ "porree.wireguard:9100" ];
      example = [ "hostname.wireguard:9100" ];
      description = "Targets to monitor with the node-exporter";
    };
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files = {
      "prometheus/home-assistant-token" = {
        owner = "prometheus";
        path = "/var/lib/prometheus2/home-assistant-token";
      };
      "prometheus/drone-token" = {
        owner = "prometheus";
        path = "/var/lib/prometheus2/drone-token";
      };
    };

    services.prometheus = {
      enable = true;

      # Disable config checks. They will fail because they run sandboxed and
      # can't access external files, e.g. the secrets stored in /run/keys
      # https://github.com/NixOS/nixpkgs/blob/d89d7af1ba23bd8a5341d00bdd862e8e9a808f56/nixos/modules/services/monitoring/prometheus/default.nix#L1732-L1738
      checkConfig = false;

      webExternalUrl = "https://vpn.prometheus.pablo.tools";
      extraFlags =
        [ "--log.level=debug" "--storage.tsdb.retention.size='6GB'" ];
      # ruleFiles = [ ./alert-rules.json ];
      # ruleFiles = [ ./alert-rules.yml ];
      ruleFiles = [
        (pkgs.writeText "prometheus-rules.yml" (builtins.toJSON {
          groups = [{
            name = "alerting-rules";
            rules = import ./alert-rules.nix { inherit lib; };
          }];
        }))
      ];
      alertmanagers =
        [{ static_configs = [{ targets = [ "localhost:9093" ]; }]; }];

      scrapeConfigs = [
        # TODO fix esp config
        # {
        #   job_name = "esphome";
        #   scrape_interval = "30s";
        #   scheme = "http";
        #   static_configs = [{
        #     targets = [
        #       "http://192.168.2.145"
        #       "http://192.168.2.146"
        #     ];
        #   }];
        # }
        # {
        #   job_name = "esphome";
        #   scheme = "http";
        #   scrape_interval = "60s";
        #   metrics_path = "/metrics";
        #   static_configs = [{ targets = [ 
        #     "192.168.2.147"
        #   ]; }];
        # }
        {
          job_name = "drone";
          scheme = "https";
          bearer_token_file = config.lollypops.secrets.files."prometheus/drone-token".path;
          static_configs = [{ targets = [ "drone.lounge.rocks" ]; }];
        }
        {
          job_name = "homeassistant_influx";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [{ targets = [ "birne.wireguard:9273" ]; }];
        }
        {
          job_name = "homeassistant";
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";
          bearer_token_file = config.lollypops.secrets.files."prometheus/home-assistant-token".path;
          scheme = "http";
          static_configs = [{ targets = [ "birne.wireguard:8123" ]; }];
        }
        {
          job_name = "backup-reports";
          scrape_interval = "60m";
          metrics_path = "/probe";
          static_configs = [{ targets = cfg.jsonTargets; }];

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
                "127.0.0.1:7979"; # The blackbox exporter's real hostname:port.
            }
          ];
        }


        {
          job_name = "restic-exporter";
          scrape_interval = "1h";
          metrics_path = "/probe";
          static_configs = [{ targets = [ "ahorn" ]; }];
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
                "127.0.0.1:8999";
            }
          ];
        }




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

          # global = {
          # The smarthost and SMTP sender used for mail notifications.
          # smtp_smarthost = "mail.thalheim.io:587";
          # smtp_from = "alertmanager@thalheim.io";
          # smtp_auth_username = "alertmanager@thalheim.io";
          # smtp_auth_password = "$SMTP_PASSWORD";
          # };

          route = {
            receiver = "all";
            group_by = [ "instance" ];
            group_wait = "30s";
            group_interval = "2m";
            repeat_interval = "24h";
          };


          receivers = [
            {
              name = "all";
              webhook_configs = [
                { url = "http://127.0.0.1:11000/alert"; } # matrix-hook
                {
                  url = with config.pinpox.services.alertmanager-ntfy;
                    "http://${httpAddress}:${httpPort}";
                } # alertmanger-ntfy
              ];
            }
          ];
        };
      };
    };
  };
}
