{ settings, roles, meta }:
{ config, lib, pkgs, ... }:
let
  prometheusHosts = builtins.attrNames (roles.prometheus.machines or { });
  lokiHosts = builtins.attrNames (roles.loki.machines or { });

  oidc = settings.oidc;
in
{
  # SMTP password file
  clan.core.vars.generators."grafana".prompts.smtp-password.persist = true;

  # OIDC client secret + Authelia-side hash.
  #   client_secret      → raw value, read by grafana via $__file{}
  #   client_secret_hash → argon2 hash, read by Authelia via client_secret_file
  clan.core.vars.generators."grafana-oidc" = lib.mkIf oidc.enable {
    share = true;
    files.client_secret = {
      owner = "grafana";
      group = "authelia-main";
      mode = "0440";
    };
    files.client_secret_hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [
      coreutils
      openssl
      authelia
      gnused
    ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      authelia crypto hash generate argon2 --password "$(cat $out/client_secret)" \
        | sed 's/^Digest: //' > $out/client_secret_hash
    '';
  };

  # Grafana secret key for signing
  clan.core.vars.generators."grafana-secret-key" = {
    files."secret-key".owner = "grafana";
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      openssl rand -hex 32 > "$out/secret-key"
    '';
  };

  # Backup Graphana dir, contains stateful config
  pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/grafana" ];

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts."${settings.domain}".extraConfig = "reverse_proxy 127.0.0.1:9005";
  };

  # Graphana fronend
  services.grafana = {

    enable = true;

    settings = {
      server = {
        domain = settings.domain;
        root_url = "https://${settings.domain}/";
        # Default is 3000
        http_port = 9005;
        http_addr = "127.0.0.1";
      };

      security.secret_key = "$__file{${config.clan.core.vars.generators."grafana-secret-key".files."secret-key".path}}";

      # Mail notifications
      smtp = {
        enabled = true;
        host = "smtp.sendgrid.net:587";
        user = "apikey";
        passwordFile = "${config.clan.core.vars.generators."grafana".files."smtp-password".path}";
        fromAddress = "status@pablo.tools";
      };
    }
    // lib.optionalAttrs oidc.enable {
      # SCIM is enabled by default in recent Grafana versions and intercepts
      # OIDC user provisioning, causing "Failed to create user: user not
      # found". Disable it so the standard generic_oauth flow can create users.
      feature_toggles.enableSCIM = false;

      # OIDC-only login: hide the username/password form, do not auto-create
      # local users via signup, redirect straight to the OIDC provider.
      auth = {
        disable_login_form = true;
        signout_redirect_url = "${oidc.issuer}/logout";
        # Self-healing OIDC user linking: if user_auth has no row for the
        # OIDC subject (e.g. fresh DB restore, or Authelia rebuilt and the
        # sub UUID changed), Grafana falls back to matching by email and
        # auto-creates the user_auth link. Safe here because Authelia is a
        # fully trusted IdP we control.
        oauth_allow_insecure_email_lookup = true;
      };
      users = {
        # Must be true so the OIDC provisioning path can create new users.
        # disable_login_form = true (above) already prevents the local signup
        # form from being rendered, so this only enables OIDC-initiated signup.
        allow_sign_up = true;
        auto_assign_org = true;
        auto_assign_org_role = "Admin";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = oidc.providerName;
        icon = "signin";
        auto_login = true;
        client_id = oidc.clientId;
        client_secret = "$__file{${config.clan.core.vars.generators."grafana-oidc".files.client_secret.path}}";
        scopes = "openid profile email groups";
        empty_scopes = false;
        auth_url = "${oidc.issuer}/api/oidc/authorization";
        token_url = "${oidc.issuer}/api/oidc/token";
        api_url = "${oidc.issuer}/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        email_attribute_path = "email";
        name_attribute_path = "name";
        groups_attribute_path = "groups";
        # Authelia already restricts who can reach the client via its
        # authorization policy, so anyone who successfully logs in is granted
        # Admin in Grafana.
        role_attribute_path = "'Admin'";
        allow_sign_up = true;
        use_pkce = true;
      };
    };

    # TODO provision the dashboards as currently configured

    provision.datasources.settings = {
      datasources =
        lib.optional (prometheusHosts != [ ]) {
          name = "Prometheus";
          url = "http://${builtins.head prometheusHosts}.${meta.domain}:9090";
          type = "prometheus";
          isDefault = true;
        }
        ++ lib.optional (lokiHosts != [ ]) {
          name = "loki";
          url = "http://${builtins.head lokiHosts}.${meta.domain}:3100";
          type = "loki";
        };
    };
  };
}
