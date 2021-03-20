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

  #   github = {
  #     repositories = [ "nixos/nixpkgs" "pinpox/nixos" "pinpox/nixos-home" ];
  #   };

  #   http_response = {
  #     urls = [
  #       "https://pablo.tools"
  #       "https://pass.pablo.tools"
  #       "https://status.pablo.tools/login"
  #       "https://home.pablo.tools"

  #       "https://mm.0cx.de"
  #       "https://pads.0cx.de"
  #       "https://irc.0cx.de"

  #       "https://megaclan3000.de"
  #     ];
  #   };

  services.prometheus = {
    enable = true;

    scrapeConfigs = [

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
