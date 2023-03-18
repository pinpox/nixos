{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.networking;
in
{

  options.pinpox.defaults.networking = {
    enable = mkEnableOption "Network defaults";
  };

  config = mkIf cfg.enable {

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
        94.16.114.42 porree-old.public
        94.16.108.229 porree.public
        46.38.242.17 kfbox.public
        93.177.66.52 kfbox-old
        5.181.48.121 mega.public

        # VPN protected services

        192.168.7.1 vpn.motion.pablo.tools
        192.168.7.1 vpn.octoprint.pablo.tools


        # 192.168.7.1 vpn.influx.pablo.tools
        192.168.7.1 vpn.alerts.pablo.tools
        192.168.7.1 vpn.prometheus.pablo.tools
        192.168.7.1 vpn.notify.pablo.tools
        # 192.168.7.4 files.pablo.tools
        192.168.7.1 vpn.s3.pablo.tools
        192.168.7.1 vpn.minio.pablo.tools
      '';
    };
  };
}
