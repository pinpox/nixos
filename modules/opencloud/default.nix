{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.opencloud;
in
{

  options.pinpox.services.opencloud = {
    enable = mkEnableOption "OpenCloud file sync and sharing";

    host = mkOption {
      type = types.str;
      default = "cloud.pablo.tools";
      description = "Host serving OpenCloud";
    };

    port = mkOption {
      type = types.port;
      default = 9200;
      description = "Port OpenCloud listens on";
    };

    oidcIssuer = mkOption {
      type = types.str;
      default = "https://auth.pablo.tools";
      description = "OIDC issuer URL (Authelia)";
    };

    oidcClientId = mkOption {
      type = types.str;
      default = "opencloud";
      description = "OIDC client ID";
    };

  };

  config = mkIf cfg.enable {

    # Backup
    pinpox.services.restic-client.backup-paths-onsite = [ "/var/lib/opencloud" ];
    pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/opencloud" ];

    # Generate required secrets
    clan.core.vars.generators."opencloud" = {
      files.envfile = {
        owner = "opencloud";
        group = "opencloud";
      };

      runtimeInputs = with pkgs; [
        coreutils
        openssl
        util-linux
      ];

      script = ''
        mkdir -p $out

        # Generate required secrets (matching opencloud init output)
        SERVICE_ACCOUNT_ID=$(uuidgen)
        STORAGE_UUID=$(uuidgen)

        # Generate LDAP passwords (same password used by multiple services)
        REVA_PASSWORD=$(openssl rand -base64 24)
        IDM_PASSWORD=$(openssl rand -base64 24)
        IDP_PASSWORD=$(openssl rand -base64 24)
        ADMIN_PASSWORD=$(openssl rand -base64 24)

        {
          echo "OC_JWT_SECRET=$(openssl rand -base64 24)"
          echo "OC_TRANSFER_SECRET=$(openssl rand -base64 24)"
          echo "OC_MACHINE_AUTH_API_KEY=$(openssl rand -base64 24)"
          echo "OC_SYSTEM_USER_ID=$(uuidgen)"
          echo "OC_SYSTEM_USER_API_KEY=$(openssl rand -base64 24)"
          echo "OC_ADMIN_USER_ID=$(uuidgen)"
          echo "GRAPH_APPLICATION_ID=$(uuidgen)"
          echo "OC_SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID"
          echo "OC_SERVICE_ACCOUNT_SECRET=$(openssl rand -base64 24)"
          echo "STORAGE_USERS_MOUNT_ID=$STORAGE_UUID"
          echo "GATEWAY_STORAGE_USERS_MOUNT_ID=$STORAGE_UUID"
          echo "THUMBNAILS_TRANSFER_SECRET=$(openssl rand -base64 24)"
          echo "COLLABORATION_WOPI_SECRET=$(openssl rand -base64 24)"
          echo "OC_URL_SIGNING_SECRET=$(openssl rand -base64 24)"

          # LDAP bind passwords for internal services
          echo "IDM_ADMIN_PASSWORD=$ADMIN_PASSWORD"
          echo "IDM_SVC_PASSWORD=$IDM_PASSWORD"
          echo "IDM_REVASVC_PASSWORD=$REVA_PASSWORD"
          echo "IDM_IDPSVC_PASSWORD=$IDP_PASSWORD"
          echo "GRAPH_LDAP_BIND_PASSWORD=$IDM_PASSWORD"
          echo "OC_LDAP_BIND_PASSWORD=$REVA_PASSWORD"
          echo "LDAP_BIND_PASSWORD=$REVA_PASSWORD"
          echo "AUTH_BASIC_LDAP_BIND_PASSWORD=$REVA_PASSWORD"
          echo "GROUPS_LDAP_BIND_PASSWORD=$REVA_PASSWORD"
          echo "USERS_LDAP_BIND_PASSWORD=$REVA_PASSWORD"
          echo "IDP_LDAP_BIND_PASSWORD=$IDP_PASSWORD"
        } > $out/envfile
      '';
    };

    services.opencloud = {
      enable = true;
      url = "https://${cfg.host}";
      address = "127.0.0.1";
      port = cfg.port;
      environmentFile = config.clan.core.vars.generators."opencloud".files."envfile".path;

      environment = {
        OC_INSECURE = "true";
        OC_LOG_LEVEL = "warn";

        # Disable TLS on proxy - Caddy handles TLS termination
        PROXY_TLS = "false";

        # Disable built-in IDP since we use external OIDC (Authelia)
        OC_EXCLUDE_RUN_SERVICES = "idp";

        # External OIDC configuration
        OC_OIDC_ISSUER = cfg.oidcIssuer;
        PROXY_OIDC_ISSUER = cfg.oidcIssuer;
        PROXY_OIDC_REWRITE_WELLKNOWN = "false";
        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
        PROXY_OIDC_SKIP_USER_INFO = "false";

        # OIDC client ID for web
        WEB_OIDC_CLIENT_ID = cfg.oidcClientId;

        # Auto-provision accounts from OIDC
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_AUTOPROVISION_CLAIM_USERNAME = "preferred_username";
        PROXY_AUTOPROVISION_CLAIM_EMAIL = "email";
        PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME = "name";
        PROXY_AUTOPROVISION_CLAIM_GROUPS = "groups";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
        GRAPH_USERNAME_MATCH = "none";

        # Avoid port conflicts with prometheus exporters (9115 = blackbox_exporter)
        WEB_HTTP_ADDR = "127.0.0.1:9105";
        WEBDAV_HTTP_ADDR = "127.0.0.1:9116";
        COLLABORATION_HTTP_ADDR = "127.0.0.1:9300";
        COLLABORATION_GRPC_ADDR = "127.0.0.1:9301";
      };

      # OpenCloud configuration (prevents init service from running)
      settings = {
        # Main opencloud config - non-empty value prevents opencloud init from running
        opencloud = {
          graph.spaces.insecure = true;
          proxy.insecure_backends = true;
        };

        # Proxy config
        proxy.csp_config_file_location = "/etc/opencloud/csp.yaml";

        # CSP - allow connecting to external OIDC provider
        csp.directives = {
          "connect-src" = ["https://${cfg.host}/" cfg.oidcIssuer];
          "frame-src" = ["https://${cfg.host}/" cfg.oidcIssuer];
          "script-src" = ["'self'" "'unsafe-inline'" "'unsafe-eval'"];
        };

        # Web UI OIDC configuration
        web.web.config = {
          server = "https://${cfg.host}";
          oidc = {
            metadata_url = "${cfg.oidcIssuer}/.well-known/openid-configuration";
            authority = cfg.oidcIssuer;
            client_id = cfg.oidcClientId;
            response_type = "code";
            scope = "openid offline_access profile email groups";
          };
        };
      };
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts = {
      "${cfg.host}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
