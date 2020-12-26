{ config, pkgs, lib, ... }: {
  services.zabbixServer.enable = true;
  services.zabbixWeb = {
    enable = true;
    virtualHost = {
      hostName = "porree.public";
      adminAddr = "webmaster@localhost";
    };
  };
  # technically not needed on the server, but good for testing.
  services.zabbixAgent = {
    enable = true;
    server = "localhost";
  };

  # Open necessary ports
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 80 443 22 ];

  #   interfaces.wg0.allowedTCPPorts = [ 2812 ];
  # };
}
