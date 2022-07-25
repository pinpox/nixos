{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.metrics;
in
{

  options.pinpox.metrics.restic = {
    enable = mkEnableOption "prometheus restic-exporter metrics collection";
  };

  options.pinpox.metrics.node = {
    enable = mkEnableOption "prometheus node-exporter metrics collection";
  };

  options.pinpox.metrics.json = {
    enable = mkEnableOption "prometheus json metrics collection";
  };

  options.pinpox.metrics.blackbox = {
    enable = mkEnableOption "prometheus blackbox-exporter metrics collection";
  };

  # imports = [ restic-exporter.nixosModules.default ];

  config = {

    lollypops.secrets.files =
      if cfg.restic.enable then
        { "restic-exporter/envfile" = { }; }
      else { };

    services.restic-exporter = {
      enable = cfg.restic.enable;
      environmentFile = "${config.lollypops.secrets.files."restic-exporter/envfile".path}";
      port = "8999";
    };

    services.prometheus.exporters = {
      node = mkIf cfg.node.enable {
        enable = true;
        # Default port is 9100
        # Listen on 0.0.0.0, bet we only open the firewall for wg0
        openFirewall = false;
        enabledCollectors = [ "systemd" ];

        extraFlags = [ "--collector.textfile.directory=/etc/nix" ];
      };

      json = mkIf cfg.json.enable {
        enable = true;
        # listenAddress = "${config.pinpox.wg-client.clientIp}";
        listenAddress = "127.0.0.1";

        configFile = pkgs.writeTextFile {
          name = "json-exporter-config";
          text = ''
            ---
            metrics:
            - name: borg_last_snapshot
              type: object
              help: Last snapshot stats
              path: "{.archives[0]}"
              labels:
                hostname: "{.hostname}"
              values:
                duration: "{.duration}"
                nfiles: "{.stats.nfiles}"
                compressed_size: "{.stats.compressed_size}"
                deduplicated_size: "{.stats.deduplicated_size}"
                original_size: "{.stats.original_size}"
          '';
        };
      };

      blackbox = mkIf cfg.blackbox.enable {
        enable = true;
        # Default port is 9115
        # Listen on 0.0.0.0, bet we only open the firewall for wg0
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
    };

    #   github = {
    #     repositories = [ "nixos/nixpkgs" "pinpox/nixos" "pinpox/nixos-home" ];
    #   };

    # Open firewall ports on the wireguard interface
    networking.firewall.interfaces.wg0.allowedTCPPorts =
      lib.optional cfg.blackbox.enable 9115
      ++ lib.optional cfg.node.enable 9100;
  };
}
