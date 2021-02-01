{ config, pkgs, ... }: {

  systemd.services.telegraf.path = with pkgs; [ lm_sensors iputils ];

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

        # TODO check out monit, SMART and ethtool inputs
        # https://gist.github.com/pinpox/9345515664f8bddbd913f5559cdeac31
        # smart = {};
        # monit = {};
        # ethtool = {};

        disk = { ignore_fs = [ "tmpfs" "devtmpfs" "devfs" ]; };
        diskio = { };
        io = { };
        kernel = { };
        kernel_vmstat = { };
        mem = { };
        net = { };
        netstat = { };
        processes = { };
        sensors = { };
        swap = { };
        system = { };
        systemd_units = { };
        wireguard = { };

        # Generic socket listener capable of handling multiple socket types.
        # socket_listener = {
        #   service_address = "tcp://:8094";
        #   service_address = "tcp://127.0.0.1:http";
        #   service_address = "tcp4://:8094";
        #   service_address = "tcp6://:8094";
        #   service_address = "udp://:8094";
        #   service_address = "unix:///tmp/telegraf.sock";
        #   service_address = "unixgram:///tmp/telegraf.sock";
        # };

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
