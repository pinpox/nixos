{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.networking;
in
{

  options.pinpox.defaults.networking = {
    enable = mkEnableOption "Network defaults";
  };

  config = mkIf cfg.enable {

    networking = {

      # Additional hosts to put in /etc/hosts
      extraHosts =

        let
          mkWgEntry =
            host:
            "${
              builtins.readFile (
                config.clan.core.settings.directory + "/vars/per-machine/${host}/wireguard-wg-clan-ip/ipv4/value"
              )
            } ${host}.wireguard";
        in
        ''
          # Wireguard
          ${mkWgEntry "porree"}
          ${mkWgEntry "kartoffel"}
          ${mkWgEntry "birne"}
          ${mkWgEntry "kfbox"}

          # Public
          94.16.114.42 porree-old.public
          94.16.108.229 porree.public
          46.38.242.17 kfbox.public
          93.177.66.52 kfbox-old
          5.181.48.121 mega.public

          # VPN protected services
          192.168.8.1 vpn.motion.pablo.tools
          192.168.8.1 vpn.octoprint.pablo.tools
          192.168.8.1 vpn.alerts.pablo.tools
          192.168.8.1 vpn.prometheus.pablo.tools
          192.168.8.1 vpn.notify.pablo.tools
          192.168.8.1 vpn.s3.pablo.tools
          192.168.8.1 vpn.minio.pablo.tools
        '';
    };
  };
}
