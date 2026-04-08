{ pkgs, ... }:
{
  services.prometheus.exporters.blackbox = {
    enable = true;
    # Default port is 9115
    # Listen on 0.0.0.0, but we only open the firewall for wg-clan
    openFirewall = false;

    configFile = pkgs.writeTextFile {
      name = "blackbox-exporter-config";
      text = ''
        modules:
          http_2xx:
            prober: http
            timeout: 5s
            http:
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              valid_status_codes: []  # Defaults to 2xx
              method: GET
              no_follow_redirects: false
              fail_if_ssl: false
              fail_if_not_ssl: false
              tls_config:
                insecure_skip_verify: false
              preferred_ip_protocol: "ip4" # defaults to "ip6"
              ip_protocol_fallback: true  # fallback to "ip6"
      '';
    };
  };

  networking.firewall.interfaces.wg-clan.allowedTCPPorts = [ 9115 ];
}
