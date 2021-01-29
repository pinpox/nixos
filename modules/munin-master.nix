{ config, pkgs, lib, ... }: {

  environment.systemPackages = with pkgs; [ munin ];

  services.munin-cron = {
    enable = true;
    hosts = ''
      [${config.networking.hostName}]
      address localhost
    '';
  };

  services.munin-node.enable = true;

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
    # provided by Let's Encrypt via ACME. Generation and renewal is automatic
    # if DNS is set up correctly for the (sub-)domains.
    virtualHosts = {
      # Personal homepage and blog
      "status.pablo.tools" = {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/munin";
      };
    };
  };

  # services.zabbixServer.enable = true;
  # services.zabbixWeb = {
  #   enable = true;
  #   virtualHost = {
  #     hostName = "porree.public";
  #     adminAddr = "zabbix@pablo.tools";
  #     listen = [{
  #       ip = "192.168.7.1";
  #       port = 8088;
  #     }];
  #   };
  # };
  # # technically not needed on the server, but good for testing.
  # services.zabbixAgent = {
  #   enable = true;
  #   server = "localhost";
  # };

  # # Open necessary ports
  # networking.firewall = {
  #   enable = true;
  #   # allowedTCPPorts = [ 80 443 22 ];

  #   interfaces.wg0.allowedTCPPorts = [ 8088 10051 ];
  # };

}
