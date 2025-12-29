{
  config,
  lib,
  pkgs,
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
      after = [
        "caddy.service"
        "systemd-tmpfiles-setup.service"
      ];
      requires = [
        "caddy.service"
        "systemd-tmpfiles-setup.service"
      ];
      serviceConfig.LoadCredential = [
        "admin-password:${config.clan.core.vars.generators.kanidm.files.admin-password.path}"
        "idm-admin-password:${config.clan.core.vars.generators.kanidm.files.idm-admin-password.path}"
      ];
    };

    services.kanidm = {
      enableServer = true;
      package = pkgs.kanidmWithSecretProvisioning_1_8;

      enableClient = true;
      clientSettings.uri = config.services.kanidm.serverSettings.origin;

      serverSettings = {
        origin = "https://${cfg.host}";
        domain = cfg.host;
        bindaddress = "127.0.0.1:${toString port}";
        tls_chain = "${kanidmCertsDir}/cert.pem";
        tls_key = "${kanidmCertsDir}/key.pem";
        role = "WriteReplica";
        log_level = "info";
      };

      provision = {
        enable = true;
        autoRemove = false;
        adminPasswordFile = "/run/credentials/kanidm.service/admin-password";
        idmAdminPasswordFile = "/run/credentials/kanidm.service/idm-admin-password";

        persons = {
          pinpox = {
            displayName = "pinpox";
            groups = [
              "unix.admins"
              "tv.users"
            ];
          };
        };
        groups = {
          "unix.admins" = { };
          "tv.users" = { };
        };
      };
    };

    clan.core.vars.generators."kanidm" = {
      files.admin-password = { };
      files.idm-admin-password = { };

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];

      script = ''
        mkdir -p $out
        xkcdpass -n 8 > $out/admin-password
        xkcdpass -n 8 > $out/idm-admin-password
      '';
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
