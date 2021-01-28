{ config, pkgs, ... }: {
  services.telegraf = {
    enable = true;
    extraConfig = {

      # Telegraph configuration
      agent.interval = "60s";

      inputs = {
        cpu = {
          percpu = true;
          totalcpu = true;
          collect_cpu_time = false;
          report_active = false;
        };

        disk = { ignore_fs = [ "tmpfs" "devtmpfs" "devfs" ]; };
        io = { };
        kernel = { };
        kernel_vmstat = { };
        mem = { };
        net = { };
        netstat = { };
        processes = { };
        swap = { };
        system = { };

      };
      outputs.prometheus_client = {
        listen = ":9273";
        metric_version = 2;
      };
    };
  };

  networking.firewall = {
    enable = true;
    interfaces.wg0.allowedTCPPorts = [ 9273 ];
  };
}
