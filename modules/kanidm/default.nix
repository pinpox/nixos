{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.kanidm;
  port = 8443;
  caddyCertsDir = "${config.services.caddy.dataDir}/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory";
  kanidmCertsDir = "/var/lib/kanidm/certs";
in
{

  options.pinpox.services.kanidm = {
    enable = mkEnableOption "kanidm identity management server";

    host = mkOption {
      type = types.str;
      default = "auth.pablo.tools";
      description = "Host serving kanidm";
      example = "signin.pablo.tools";
    };
  };

  config = mkIf cfg.enable {

    # Add kanidm to caddy group to read certs
    users.users.kanidm.extraGroups = [ "caddy" ];

    # Copy certs from Caddy to kanidm-readable location
    systemd.tmpfiles.rules = [
      "d ${kanidmCertsDir} 0750 kanidm caddy -"
      "C ${kanidmCertsDir}/cert.pem - kanidm - - ${caddyCertsDir}/${cfg.host}/${cfg.host}.crt"
      "C ${kanidmCertsDir}/key.pem - kanidm - - ${caddyCertsDir}/${cfg.host}/${cfg.host}.key"
    ];

    systemd.services.kanidm = {
      after = [ "caddy.service" "systemd-tmpfiles-setup.service" ];
      requires = [ "caddy.service" "systemd-tmpfiles-setup.service" ];
    };

    services.kanidm = {
      enableServer = true;

      serverSettings = {
        origin = "https://${cfg.host}";
        domain = cfg.host;
        bindaddress = "127.0.0.1:${toString port}";
        tls_chain = "${kanidmCertsDir}/cert.pem";
        tls_key = "${kanidmCertsDir}/key.pem";
        role = "WriteReplica";
        log_level = "info";
      };
    };

    # Backup kanidm database
    pinpox.services.restic-client.backup-paths-offsite = [
      "/var/lib/kanidm"
    ];

    # Reverse proxy via caddy (caddy handles ACME internally)
    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig = ''
        reverse_proxy https://127.0.0.1:${toString port} {
          transport http {
            tls_server_name ${cfg.host}
          }
        }
      '';
    };
  };
}
