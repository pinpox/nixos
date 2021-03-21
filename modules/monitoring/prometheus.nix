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
        static_configs = [{ targets = [
          "https://pablo.tools"
          "https://megaclan3000.de"
          "https://drone.lounge.rocks"
          "https://lounge.rocks"
          "https://pass.pablo.tools"
          "https://vpn.pablo.tools"
          "https://pinpox.github.io/nixos/"
          "https://pads.0cx.de"
          "https://mm.0cx.de"
          "https://irc.0cx.de"
        ]; }];

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
        static_configs = [{
          targets = [
            "ahorn.wireguard:9100"
            "birne.wireguard:9100"
            "kartoffel.wireguard:9100"
            "kfbox.wireguard:9100"
            "mega.wireguard:9100"
            "porree.wireguard:9100"
          ];
        }];
      }
    ];
  };
}
