{ config, pkgs, lib, ... }: {

  networking.firewall = {
    enable = true;
    interfaces.wg0.allowedTCPPorts = [ 2812 ];
  };

  services.monit = {
    enable = true;
    config = ''
      include /var/src/secrets/monit/conf
      include /var/src/machine-config/modules/monit/configs/default
      include /var/src/machine-config/modules/monit/configs/${config.networking.hostName}"
    '';

  };
}
