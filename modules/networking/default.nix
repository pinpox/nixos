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
          wgIp =
            host:
            builtins.readFile (
              config.clan.core.settings.directory + "/vars/per-machine/${host}/wireguard-wg-clan-ip/ipv4/value"
            );
          mkWgEntry = host: "${wgIp host} ${host}.wireguard";
          porreeWgIp = wgIp "porree";
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

          # VPN protected services (porree via wireguard)
          ${porreeWgIp} vpn.motion.pablo.tools
          ${porreeWgIp} vpn.alerts.pablo.tools
          ${porreeWgIp} vpn.prometheus.pablo.tools
          ${porreeWgIp} vpn.notify.pablo.tools
          ${porreeWgIp} vpn.s3.pablo.tools
          ${porreeWgIp} vpn.minio.pablo.tools
        '';
    };
  };
}
