{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.ocis;
in
{

  options.pinpox.services.ocis = {
    enable = mkEnableOption "ownCloud Infinite Scale (OCIS)";

    host = mkOption {
      type = types.str;
      default = "cloud.pablo.tools";
      description = "Host serving OCIS";
    };

    port = mkOption {
      type = types.port;
      default = 9200;
      description = "Port OCIS listens on";
    };

    oidcIssuer = mkOption {
      type = types.str;
      default = "https://auth.pablo.tools";
      description = "OIDC issuer URL (Authelia)";
    };

  };

  config = mkIf cfg.enable {

    # Backup
    pinpox.services.restic-client.backup-paths-onsite = [ "/var/lib/ocis" ];
    pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/ocis" ];

    # Generate admin password and required secrets
    clan.core.vars.generators."ocis" = {
      files.admin-password = { };
      files.envfile = {
        owner = "ocis";
        group = "ocis";
      };

      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
        openssl
        util-linux
      ];

      script = ''
        mkdir -p $out
        xkcdpass -n 5 -d- > $out/admin-password

        # Generate required secrets and IDs (matching ocis init output)
        SERVICE_ACCOUNT_ID=$(uuidgen)
        STORAGE_UUID=$(uuidgen)
        REVA_PASSWORD=$(openssl rand -base64 24)
        IDP_PASSWORD=$(openssl rand -base64 24)
        IDM_PASSWORD=$(openssl rand -base64 24)

        echo "OCIS_JWT_SECRET=$(openssl rand -base64 24)" > $out/envfile
        echo "OCIS_TRANSFER_SECRET=$(openssl rand -base64 24)" >> $out/envfile
        echo "OCIS_MACHINE_AUTH_API_KEY=$(openssl rand -base64 24)" >> $out/envfile
        echo "OCIS_SYSTEM_USER_ID=$(uuidgen)" >> $out/envfile
        echo "OCIS_SYSTEM_USER_API_KEY=$(openssl rand -base64 24)" >> $out/envfile
        echo "OCIS_ADMIN_USER_ID=$(uuidgen)" >> $out/envfile
        echo "GRAPH_APPLICATION_ID=$(uuidgen)" >> $out/envfile
        echo "OCIS_SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID" >> $out/envfile
        echo "OCIS_SERVICE_ACCOUNT_SECRET=$(openssl rand -base64 24)" >> $out/envfile
        echo "STORAGE_USERS_MOUNT_ID=$STORAGE_UUID" >> $out/envfile
        echo "GATEWAY_STORAGE_USERS_MOUNT_ID=$STORAGE_UUID" >> $out/envfile
        echo "THUMBNAILS_TRANSFER_SECRET=$(openssl rand -base64 24)" >> $out/envfile
        # LDAP/IDM passwords (needed for internal services)
        echo "IDM_ADMIN_PASSWORD=$(cat $out/admin-password)" >> $out/envfile
        echo "IDM_SVC_PASSWORD=$IDM_PASSWORD" >> $out/envfile
        echo "IDM_REVASVC_PASSWORD=$REVA_PASSWORD" >> $out/envfile
        echo "IDM_IDPSVC_PASSWORD=$IDP_PASSWORD" >> $out/envfile
        # Graph service uses libregraph user (IDM_SVC_PASSWORD)
        echo "GRAPH_LDAP_BIND_PASSWORD=$IDM_PASSWORD" >> $out/envfile
        # Other services use reva user
        echo "OCIS_LDAP_BIND_PASSWORD=$REVA_PASSWORD" >> $out/envfile
        echo "LDAP_BIND_PASSWORD=$REVA_PASSWORD" >> $out/envfile
        echo "AUTH_BASIC_LDAP_BIND_PASSWORD=$REVA_PASSWORD" >> $out/envfile
        echo "GROUPS_LDAP_BIND_PASSWORD=$REVA_PASSWORD" >> $out/envfile
        echo "USERS_LDAP_BIND_PASSWORD=$REVA_PASSWORD" >> $out/envfile
      '';
    };

    services.ocis = {
      enable = true;
      # package = pkgs.ocis-bin;
      url = "https://${cfg.host}";
      address = "127.0.0.1";
      port = cfg.port;
      environmentFile = config.clan.core.vars.generators."ocis".files."envfile".path;

      environment = {
        OCIS_INSECURE = "true";
        PROXY_TLS = "false";
        OCIS_LOG_LEVEL = "warn";

        # Disable built-in IDP since we use external OIDC (Authelia)
        # Keep IDM running to store auto-provisioned users
        OCIS_EXCLUDE_RUN_SERVICES = "idp";

        # Avoid port conflicts with prometheus exporters
        WEB_HTTP_ADDR = "127.0.0.1:9105";
        WEBDAV_HTTP_ADDR = "127.0.0.1:9116";

        # OIDC configuration
        WEB_OIDC_CLIENT_ID = "ocis";
        PROXY_OIDC_ISSUER = cfg.oidcIssuer;
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
        PROXY_OIDC_SKIP_USER_INFO = "false";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_AUTOPROVISION_CLAIM_USERNAME = "preferred_username";
        PROXY_AUTOPROVISION_CLAIM_EMAIL = "email";
        PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME = "name";
        PROXY_AUTOPROVISION_CLAIM_GROUPS = "groups";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
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
