{ ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    # Default port is 9100
    # Listen on 0.0.0.0, but we only open the firewall for wg-clan
    openFirewall = false;
    enabledCollectors = [
      "cgroups"
      "systemd"
    ];

    extraFlags = [ "--collector.textfile.directory=/etc/nix" ];
  };

  networking.firewall.interfaces.wg-clan.allowedTCPPorts = [ 9100 ];
}
