{ config, pkgs, ... }: {
 # grafana configuration
  services.grafana = {
    enable = true;
    domain = "porree.public";
    port = 2342;
    addr = "192.168.7.1";
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };

    scrapeConfigs = [
      {
        job_name = "porree";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };

    # Block anything that is not HTTP(s) or SSH.
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 9001 2342 ];
    };

  # # nginx reverse proxy
  # services.nginx.virtualHosts.${config.services.grafana.domain} = {
  #   locations."/" = {
  #       proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
  #       proxyWebsockets = true;
  #   };
  # };
}
