{
  lib,
  pkgs,
  config,
  pinpox-utils,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.monitoring-server;
in
{

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
      default = [ ];
      example = [ "http://birne.wireguard/restic-ahorn.json" ];
      description = "Targets to probe with the json-exporter";
    };
  };

  config = mkIf cfg.enable {

    clan.core.vars.generators."restic-exporter" = pinpox-utils.mkEnvGenerator [
      "RESTIC_PASSWORD"
      "AWS_ACCESS_KEY_ID"
      "AWS_SECRET_ACCESS_KEY"
      "RESTIC_REPOSITORY"
    ];

    # services.restic-exporter = {
    #   enable = cfg.restic.enable;
    #   environmentFile = "${config.clan.core.vars.generators."restic-exporter".files."envfile".path}";
    #   port = "8999";
    # };

    clan.core.vars.generators."prometheus" = {

      prompts.token.description = "Home-assistant token for prometheus";

      files.home-assistant-token = {
        group = "prometheus";
        owner = "prometheus";
      };

      script = ''
        printf "%s" "$(cat $prompts/token)" > $out/home-assistant-token
      '';

    };

    services.prometheus = {
      enable = true;

      # Disable config checks. They will fail because they run sandboxed and
      # can't access external files, e.g. the secrets stored in /run/keys
      # https://github.com/NixOS/nixpkgs/blob/d89d7af1ba23bd8a5341d00bdd862e8e9a808f56/nixos/modules/services/monitoring/prometheus/default.nix#L1732-L1738
      checkConfig = false;

      webExternalUrl = "https://vpn.prometheus.pablo.tools";
      extraFlags = [
        "--log.level=debug"
        "--storage.tsdb.retention.size='6GB'"
      ];
      # ruleFiles = [ ./alert-rules.json ];
      # ruleFiles = [ ./alert-rules.yml ];
      ruleFiles = [
        (pkgs.writeText "prometheus-rules.yml" (
          builtins.toJSON {
            groups = [
              {
                name = "alerting-rules";
                rules = import ./alert-rules.nix { inherit lib; };
              }
            ];
          }
        ))
      ];
      alertmanagers = [ { static_configs = [ { targets = [ "localhost:9093" ]; } ]; } ];

      scrapeConfigs = [
        {
          job_name = "homeassistant_influx";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [ { targets = [ "birne.wireguard:9273" ]; } ];
        }
        {
          job_name = "homeassistant";
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";
          bearer_token_file = config.clan.core.vars.generators."prometheus".files."home-assistant-token".path;
          scheme = "http";
          static_configs = [ { targets = [ "birne.wireguard:8123" ]; } ];
        }
        {
          job_name = "backup-reports";
          scrape_interval = "60m";
          metrics_path = "/probe";
          static_configs = [ { targets = cfg.jsonTargets; } ];

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
              replacement = "127.0.0.1:7979"; # The blackbox exporter's real hostname:port.
            }
          ];
        }
        {
          job_name = "restic-exporter";
          scrape_interval = "1h";
          metrics_path = "/probe";
          static_configs = [
            {
              # Build list of all hosts that have restic-client.enable set to "true"
              targets = (
                builtins.attrNames (
                  lib.filterAttrs (n: v: v.config.pinpox.services.restic-client.enable) flake-self.nixosConfigurations
                )
              );
            }
          ];
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
              replacement = "127.0.0.1:${builtins.toString config.services.restic-exporter.port}";
            }
          ];
        }
        {
          job_name = "blackbox";
          scrape_interval = "2m";
          metrics_path = "/probe";
          params = {
            module = [ "http_2xx" ];
          };
          static_configs = [ { targets = cfg.blackboxTargets; } ];

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
              replacement = "127.0.0.1:9115"; # The blackbox exporter's real hostname:port.
            }
          ];
        }
        {
          job_name = "node-stats";
          static_configs = [
            {
              # Build list of all hosts that have pinpox.metrics.node.enable set to
              # "true", adding ".wireguard:9100"
              targets = (
                map (x: x + ".wireguard:9100") (
                  builtins.attrNames (
                    lib.filterAttrs (n: v: v.config.pinpox.metrics.node.enable) flake-self.nixosConfigurations
                  )
                )
              );
            }
          ];
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
                { url = with config.services.alertmanager-ntfy; "http://${httpAddress}:${httpPort}"; } # alertmanger-ntfy
              ];
            }
          ];
        };
      };
    };
  };
}
