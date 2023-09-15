{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.sso;
in
{

  # options.pinpox.services.monitoring-server.loki = {
  #   enable = mkEnableOption "Loki log collector";
  # };

  config = mkIf config.pinpox.services.sso.enable {

    lollypops.secrets.files = {
      "authelia/jwt_secret" = { owner = "authelia-test"; group-name = "authelia-test"; };
      "authelia/oidc_hmac_secret" = { owner = "authelia-test"; group-name = "authelia-test"; };
      "authelia/oidc_issuer_private_key" = { owner = "authelia-test"; group-name = "authelia-test"; };
      "authelia/storage_encryption_key" = { owner = "authelia-test"; group-name = "authelia-test"; };
      "authelia/ldap_password" = { owner = "authelia-test"; group-name = "authelia-test"; };
    };

    systemd.services.authelia-test = {
      serviceConfig = {
        LoadCredential = [
          "jwt_secret:${config.lollypops.secrets.files."authelia/jwt_secret".path}"
          "oidc_hmac_secret:${config.lollypops.secrets.files."authelia/oidc_hmac_secret".path}"
          "oidc_issuer_private_key:${config.lollypops.secrets.files."authelia/oidc_issuer_private_key".path}"
          "storage_encryption_key:${config.lollypops.secrets.files."authelia/storage_encryption_key".path}"
          "ldap_password:${config.lollypops.secrets.files."authelia/ldap_password".path}"
        ];
      };
    };


    services.caddy = {
      virtualHosts = {

        # Expose authelia
        "auth.${cfg.authHost}".extraConfig = "reverse_proxy 127.0.0.1:9091";
      };
    };


    # TODO Rename instance to something better than test
    services.authelia.instances.test = {
      enable = true;

      # Set the secrets manually via env vars, so we can use systemd's LoadCredential
      secrets.manual = true;
      environmentVariables = {
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "%d/oidc_hmac_secret";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = "%d/oidc_issuer_private_key";
        AUTHELIA_JWT_SECRET_FILE = "%d/jwt_secret";
        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/storage_encryption_key";
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap_password";
      };

      # https://github.com/authelia/authelia/blob/master/config.template.yml
      settings = {

        authentication_backend = {
          # file = { path = "/var/lib/authelia-test/users_database.yml"; watch = false; };
          ldap = {
            implementation = "custom";

            url = "ldap://127.0.0.1";
            timeout = "5s";
            start_tls = false;

            tls = {

              ## Server Name for certificate validation (in case it's not set correctly in the URL).
              # server_name: ldap.example.com

              ## Skip verifying the server certificate (to allow a self-signed certificate).
              ## In preference to setting this we strongly recommend you add the public portion of the certificate to the
              ## certificates directory which is defined by the `certificates_directory` option at the top of the config.
              skip_verify = false;
              ## Minimum TLS version for either Secure LDAP or LDAP StartTLS.
              minimum_version = "TLS1.2";

            };
            ## The distinguished name of the container searched for objects in the directory information tree.
            ## See also: additional_users_dn, additional_groups_dn.
            base_dn = "dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}";

            ## The attribute holding the username of the user. This attribute is used to populate the username in the session
            ## information. It was introduced due to #561 to handle case insensitive search queries. For you information,
            ## Microsoft Active Directory usually uses 'sAMAccountName' and OpenLDAP usually uses 'uid'. Beware that this
            ## attribute holds the unique identifiers for the users binding the user and the configuration stored in database.
            ## Therefore only single value attributes are allowed and the value must never be changed once attributed to a user
            ## otherwise it would break the configuration for that user. Technically, non-unique attributes like 'mail' can also
            ## be used but we don't recommend using them, we instead advise to use the attributes mentioned above
            ## (sAMAccountName and uid) to follow https://www.ietf.org/rfc/rfc2307.txt.
            username_attribute = "cn";

            ## The additional_users_dn is prefixed to base_dn and delimited by a comma when searching for users.
            ## i.e. with this set to OU=Users and base_dn set to DC=a,DC=com; OU=Users,DC=a,DC=com is searched for users.
            additional_users_dn = "ou=users";

            ## The users filter used in search queries to find the user profile based on input filled in login form.
            ## Various placeholders are available in the user filter:
            ## - {input} is a placeholder replaced by what the user inputs in the login form.
            ## - {username_attribute} is a mandatory placeholder replaced by what is configured in `username_attribute`.
            ## - {mail_attribute} is a placeholder replaced by what is configured in `mail_attribute`.
            ##
            ## Recommended settings are as follows:
            ## - Microsoft Active Directory: (&({username_attribute}={input})(objectCategory=person)(objectClass=user))
            ## - OpenLDAP:
            ##   - (&({username_attribute}={input})(objectClass=person))
            ##   - (&({username_attribute}={input})(objectClass=inetOrgPerson))
            ##
            ## To allow sign in both with username and email, one can use a filter like
            ## (&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))
            users_filter = "(&({username_attribute}={input})(objectClass=inetOrgPerson))";

            ## The additional_groups_dn is prefixed to base_dn and delimited by a comma when searching for groups.
            ## i.e. with this set to OU=Groups and base_dn set to DC=a,DC=com; OU=Groups,DC=a,DC=com is searched for groups.
            additional_groups_dn = "ou=groups";

            ## The groups filter used in search queries to find the groups of the user.
            ## - {input} is a placeholder replaced by what the user inputs in the login form.
            ## - {username} is a placeholder replace by the username stored in LDAP (based on `username_attribute`).
            ## - {dn} is a matcher replaced by the user distinguished name, aka, user DN.
            ## - {username_attribute} is a placeholder replaced by what is configured in `username_attribute`.
            ## - {mail_attribute} is a placeholder replaced by what is configured in `mail_attribute`.
            ##
            ## If your groups use the `groupOfUniqueNames` structure use this instead:
            ##    (&(uniquemember={dn})(objectclass=groupOfUniqueNames))
            # groups_filter =  "(&(member={dn})(objectclass=groupOfNames))";
            groups_filter = "(&(objectClass=groupOfNames)(member={dn}))";


            # groups_filter = "(&(uniqueMember={dn})(objectclass=groupOfNames))";
            ## The attribute holding the name of the group.
            group_name_attribute = "cn";

            ## The attribute holding the mail address of the user. If multiple email addresses are defined for a user, only the
            ## first one returned by the LDAP server is used.
            # mail_attribute: mail

            ## The attribute holding the display name of the user. This will be used to greet an authenticated user.
            # display_name_attribute: displayname

            ## The username and password of the admin user.
            user = "cn=${cfg.ldapAutheliaUser.username},ou=users,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}";

            # Password set via environment variable above
          };
        };

        access_control.default_policy = "deny";
        access_control.rules = [
          { domain = "auth.${cfg.authHost}"; policy = "bypass"; }
          { domain = "whoami.${cfg.authHost}"; policy = "two_factor"; }
          { domain = "todo.${cfg.authHost}"; policy = "one_factor"; }
          {
            domain = "whoami-admin.${cfg.authHost}";
            policy = "two_factor";
            subject = [ "group:admin" ];
          }
        ];

        storage.local.path = "/var/lib/authelia-test/db.sqlite3";
        notifier.filesystem.filename = "/var/lib/authelia-test/notification.txt";
        session.domain = "${cfg.authHost}";


        # TODO make this configurable with an option
        identity_providers.oidc.clients = [

          # TODO add here vs. in dex
          # TODO Add miniflux
          # TODO Remove gitea apps

          # Generate secrets with:
          # authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric
          # Random Password: 2sxXQQo4iaVGlE9lqILcBSi2SEoqjQwY8Ux8hPn4Hka1lVUCNLwCW7zTkovfGequ
          # Digest: $argon2id$v=19$m=65536,t=3,p=4$9M6trA7vCmFtvnQ2pfvPUEE16D5mY0XmeCeJoiRPWe6AbVpkIAZNw
          {
            id = "vikunja";
            description = "Vikunja";
            redirect_uris = [ "https://todo.0cx.de/auth/openid/authelia" ];
            secret = "$argon2id$v=19$m=65536,t=3,p=4$Fk26tkCBitbQgagtpd8cUw$OYxOx0lUoSDNdvcGFVCzFbAGWJs0tvdieK8oS0VPcck";
            authorization_policy = "one_factor";
            scopes = [
              "openid"
              "email"
              "profile"
              # groups
            ];

          }

          {
            id = "dex";
            description = "dex";
            redirect_uris = [ "https://login.0cx.de/callback" ];
            secret = "$argon2id$v=19$m=65536,t=3,p=4$8Q1EGjkxP7kCdqMzHEm41Q$RGCHqes9D5OnU/6x/Bt+PtNiCF9VQzVl+0iFErhYBNs";
            scopes = [
              "openid"
              "email"
              "profile"
              # groups
            ];
          }
        ];

        default_2fa_method = "webauthn";
        server = {
          host = "127.0.0.1";
          port = 9091;
        };

        # TODO collect logs
        log = {
          #   file_path
          format = "text"; # defaults to json
          #   keep_stdout
          #   level
        };

        # TODO collect metrics
        telemetry.metrics = {
          address = "tcp://127.0.0.1:9959";
          enabled = true;
        };

        theme = "auto"; # "dark", "grey", "light"
      };
    };



  };
}
