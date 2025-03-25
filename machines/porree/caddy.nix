{
  config,
  pkgs,
  ...
}:
let
  caddy-authfiles = config.clan.core.vars.generators."caddy-basicauth".files;

  mkBasicAuthFiles = hosts: {

    files = builtins.listToAttrs (
      map (h: {
        name = h;
        value = { };
      }) hosts
      ++ (map (h: {
        name = "${h}.auth";
        value = {
          owner = "caddy";
          group = "caddy";
        };
      }) hosts)
    );

    prompts = builtins.listToAttrs (
      map (h: {
        name = h;
        value = {
          persist = true;
          description = "Username for ${h}";
        };
      }) hosts
    );

    runtimeInputs = with pkgs; [
      coreutils
      caddy
      xkcdpass
    ];

    validation.script = builtins.concatStringsSep "" hosts;

    script =
      ''
        mkdir -p $out
      ''
      + builtins.concatStringsSep "\n" (
        map (h: ''
          xkcdpass -d- > $out/${h}
          printf "%s %s" "$(cat $prompts/${h})" "$(cat $out/${h} | caddy hash-password)" \
            > $out/${h}.auth
        '') hosts
      );
  };
in
{

  clan.core.vars.generators."caddy-basicauth" = mkBasicAuthFiles [
    "beta.pablo.tools"
    "3dprint.pablo.tools"
    "notify.pablo.tools"
  ];

  systemd.services.caddy.restartTriggers = map (f: caddy-authfiles.${f}.path) (
    builtins.attrNames caddy-authfiles
  );
  services.caddy = {
    enable = true;

    # Handle errors for all pages
    # respond "{err.status_code} {err.status_text}"
    extraConfig = ''
      :443, :80 {
        handle_errors {
         respond * "This page does not exist or is not for your eyes." {
           close
         }
        }
      }
    '';

    # The difference between {$ and {env. is that {$ is evaluated before Caddyfile
    # parsing begins, and {env. is evaluated at runtime. This matters if your
    # config is adapted in a different environment from which it is being run.
    virtualHosts = {

      # Homepage
      "pablo.tools".extraConfig = ''
        root * /var/www/pablo-tools
        file_server
        encode zstd gzip
      '';

      # Homepage (dev)
      "beta.pablo.tools".extraConfig = ''
        root * /var/www/pablo-tools-beta
        file_server
        encode zstd gzip
        basic_auth {
          import ${config.clan.core.vars.generators."caddy-basicauth".files."beta.pablo.tools.auth".path}
        }
      '';

      # Camera (read-only) stream
      "3dprint.pablo.tools".extraConfig = ''
        reverse_proxy 192.168.2.121:8081
        basic_auth {
          import ${config.clan.core.vars.generators."caddy-basicauth".files."3dprint.pablo.tools.auth".path}
        }
      '';

      # Notifications API
      "notify.pablo.tools".extraConfig = ''
        reverse_proxy 127.0.0.1:11000
        basic_auth {
          import ${config.clan.core.vars.generators."caddy-basicauth".files."notify.pablo.tools.auth".path}
        }
      '';

      # Grafana
      "status.pablo.tools".extraConfig = "reverse_proxy 127.0.0.1:9005";

      # Home-assistant
      "home.pablo.tools".extraConfig = "reverse_proxy birne.wireguard:8123";

      # Octoprint (set /etc/hosts for clients)
      "vpn.octoprint.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 192.168.2.121:5000
      '';

      # Alertmanager
      "vpn.alerts.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:9093
      '';

      # Prometheus
      "vpn.prometheus.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:9090
      '';

      # ntfy
      "vpn.notify.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly 127.0.0.1:11000
      '';

      # Minio admin console
      "vpn.minio.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly birne.wireguard:9001
      '';

      # Minio s3 backend
      "vpn.s3.pablo.tools".extraConfig = ''
        @vpnonly {
          remote_ip 192.168.0.0/16 172.168.7.0/16
        }
        reverse_proxy @vpnonly birne.wireguard:9000
      '';
    };
  };
}
