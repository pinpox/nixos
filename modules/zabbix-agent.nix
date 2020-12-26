{ config, pkgs, lib, ... }: {
  services.zabbixAgent = {
    enable = true;
    openFirewall = true;
    server = "192.168.7.1";
  };
}
