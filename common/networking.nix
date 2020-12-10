{ config, pkgs, lib, ... }: {

  networking = {

    # Define the DNS servers
    nameservers = [ "1.1.1.1" "8.8.8.8" "192.168.2.1" ];

    # Enables wireless support via wpa_supplicant.
    # networking.wireless.enable = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # useDHCP = false;
    # interfaces.eno1.useDHCP = true;

    # Enable networkmanager
    networkmanager.enable = true;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Additional hosts to put in /etc/hosts
    extraHosts = ''
      # Wireguard
      192.168.7.1 porree.wireguard
      192.168.7.2 ahorn.wireguard
      192.168.7.3 kartoffel.wireguard
      192.168.7.4 birne.wireguard
      192.168.7.5 kfbox.wireguard
      192.168.7.6 mega.wireguard

      # Public
      94.16.114.42 porree.public
      93.177.66.52 kfbox.public
      5.181.48.121 mega.public
    '';
  };
}
