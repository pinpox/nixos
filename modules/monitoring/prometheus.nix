{ config, pkgs, ... }: {

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

  # Additional telegraf inputs that only run on monitoring host
  services.telegraf.extraConfig.inputs = {
    github = {
      repositories = [ "nixos/nixpkgs" "pinpox/nixos" "pinpox/nixos-home" ];
    };

    http_response = {
      urls = [
        "https://pablo.tools"
        "https://pass.pablo.tools"
        "https://status.pablo.tools/login"
        "https://home.pablo.tools"

        "https://mm.0cx.de"
        "https://pads.0cx.de"
        "https://irc.0cx.de"

        "https://megaclan3000.de"
      ];
    };

    ping = {
      urls = [
        "porree.wireguard"
        "ahorn.wireguard"
        "kartoffel.wireguard"
        "birne.wireguard"
        "kfbox.wireguard"
        "mega.wireguard"
      ];
    };
  };

  services.prometheus = {
    enable = true;
    # Default port is 9090

    # Prometheus node-exporter
    # exporters = {
    #   node = {
    #     enable = true;
    #     enabledCollectors = [ "systemd" ];
    #     port = 9002;
    #   };
    # };

    scrapeConfigs = [{
      job_name = "telegraf";
      scrape_interval = "120s";
      metrics_path = "/metrics";
      static_configs = [
        {
          targets = [ "porree.wireguard:9273" "kfbox.wireguard:9273" ];
          labels.location = "netcup";
        }

        {
          targets = [ "birne.wireguard:9273" ];
          labels.location = "home";
        }
      ];
    }];
  };
}
