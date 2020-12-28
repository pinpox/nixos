{ config, pkgs, lib, ... }: {
  services.zabbixServer.enable = true;
  services.zabbixWeb = {
    enable = true;
    virtualHost = {
      hostName = "porree.public";
      adminAddr = "zabbix@pablo.tools";
      listen = [{
        ip = "192.168.7.1";
        port = 8088;
      }];
    };
  };
  # technically not needed on the server, but good for testing.
  services.zabbixAgent = {
    enable = true;
    server = "localhost";
  };

  # Open necessary ports
  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ 80 443 22 ];

    interfaces.wg0.allowedTCPPorts = [ 8088 10051 ];
  };
}
