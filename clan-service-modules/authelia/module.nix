{
  settings,
  exportedUsers,
  exportedClients,
  exportedVarsGenerators,
  instanceName,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = settings.port;
  inst = instanceName;
  autheliaUser = "authelia-${inst}";

  # Primary cookie: derived from domain + publicHost. Extra domains appended.
  effectiveCookies =
    [
      {
        domain = settings.domain;
        autheliaUrl = "https://${settings.publicHost}";
      }
    ]
    ++ settings.extraCookieDomains;

  # Generic script to transform Nix JSON with *File references
  nix-to-config = ./nix-to-config.py;

  # Map a generic auth.client export to Authelia's native OIDC client schema
  mapExportedClient =
    c:
    {
      client_id = c.clientId;
      client_name = if c.clientName != "" then c.clientName else c.clientId;
      redirect_uris = c.redirectUris;
      scopes = c.scopes;
      authorization_policy = "${c.clientId}-policy";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      require_pkce = true;
      pkce_challenge_method = "S256";
    }
    // lib.optionalAttrs c.public {
      public = true;
      token_endpoint_auth_method = "none";
    }
    // lib.optionalAttrs (!c.public) {
      client_secret_file =
        config.clan.core.vars.generators."authelia-oidc-${c.clientId}".files.client_secret_hash.path;
      token_endpoint_auth_method = "client_secret_post";
    };

  # For extraClients: auto-resolve secret paths and inject default
  # authorization_policy if not explicitly set.
  resolveExtraClient =
    c:
    let
      isPublic = c.public or false;
      clientId = c.client_id or "";
      hasSecret = c ? client_secret_file;
      hasPolicy = c ? authorization_policy;
    in
    (lib.optionalAttrs (!hasPolicy) { authorization_policy = "${clientId}-policy"; })
    // c
    // lib.optionalAttrs (!isPublic && !hasSecret && clientId != "") {
      client_secret_file =
        config.clan.core.vars.generators."${clientId}-oidc".files.client_secret_hash.path;
    };

  # Convert extraClients attrset to list, injecting client_id from the key
  extraClientsList = lib.mapAttrsToList (
    id: attrs: { client_id = id; } // attrs
  ) settings.extraClients;

  # All OIDC clients: exported + resolved inline extraClients
  allClients = (map mapExportedClient exportedClients) ++ (map resolveExtraClient extraClientsList);
  hasClients = allClients != [ ];

  # Build the users JSON for nix-to-config.py
  # Each user has: displayname, email, groups, passwordFile (resolved at runtime)
  usersForJson = lib.listToAttrs (
    map (
      u:
      lib.nameValuePair u.username {
        displayname = u.displayname;
        email = u.email;
        groups = u.groups;
        passwordFile =
          config.clan.core.vars.generators."authelia-user-${u.username}".files.password-hash.path;
      }
    ) exportedUsers
  );

  usersConfigJson = pkgs.writeText "authelia-users-input.json" (
    builtins.toJSON { users = usersForJson; }
  );

  hasUsers = exportedUsers != [ ];

  # OIDC clients config JSON (with *File references resolved at runtime)
  oidcConfigJson = pkgs.writeText "authelia-oidc-input.json" (
    builtins.toJSON {
      identity_providers.oidc =
        {
          clients = allClients;
          cors = {
            endpoints = [
              "authorization"
              "token"
              "revocation"
              "introspection"
              "userinfo"
            ];
            allowed_origins_from_client_redirect_uris = true;
          };
        }
        // lib.optionalAttrs (allClients != [ ]) {
          authorization_policies =
            let
              allClientIds = map (c: c.client_id or c.clientId or "") allClients;

              # Priority: clientPolicies (raw) > clientAccess (shorthand) >
              # default (group:<clientId>-users)
              policyForClient =
                id:
                if settings.clientPolicies ? "${id}-policy" then
                  settings.clientPolicies."${id}-policy"
                else if settings.clientAccess ? "${id}" then
                  {
                    default_policy = "deny";
                    rules = map (subject: {
                      policy = "one_factor";
                      inherit subject;
                    }) settings.clientAccess.${id};
                  }
                else
                  {
                    default_policy = "deny";
                    rules = [
                      {
                        policy = "one_factor";
                        subject = "group:${id}-users";
                      }
                    ];
                  };
            in
            lib.listToAttrs (
              map (id: lib.nameValuePair "${id}-policy" (policyForClient id)) (
                lib.filter (id: id != "") allClientIds
              )
            );
        };
    }
  );
in
{
  # Per-user vars generators: auto-create password + argon2 hash for each
  # exported user
  clan.core.vars.generators = lib.listToAttrs (
    map (
      user:
      lib.nameValuePair "authelia-user-${user.username}" {
        files.password = { };
        files.password-hash.owner = autheliaUser;
        files.password-hash.restartUnits = [ "authelia-${inst}.service" ];
        runtimeInputs = with pkgs; [
          coreutils
          authelia
          xkcdpass
          gnused
        ];
        script = ''
          mkdir -p $out
          xkcdpass -n 7 -d- > $out/password
          authelia crypto hash generate argon2 --password "$(cat $out/password)" \
            | sed 's/^Digest: //' > $out/password-hash
        '';
      }
    ) exportedUsers
  )
  # OIDC client secret generators from exports. runtimeInputs is added here
  # because pkgs isn't available at inventory-eval time (where the export
  # was created).
  // lib.mapAttrs (
    _name: gen:
    gen
    // {
      runtimeInputs = with pkgs; [
        coreutils
        openssl
        authelia
        gnused
      ];
    }
  ) exportedVarsGenerators
  # Core authelia secrets (jwt, session, storage, oidc keys)
  // {
    authelia = {
      files.jwt-secret.owner = autheliaUser;
      files.session-secret.owner = autheliaUser;
      files.storage-encryption-key.owner = autheliaUser;
      files.oidc-hmac-secret.owner = autheliaUser;
      files.oidc-jwks-key.owner = autheliaUser;

      runtimeInputs = with pkgs; [
        coreutils
        openssl
      ];

      script = ''
        mkdir -p $out
        openssl rand -hex 64 > $out/jwt-secret
        openssl rand -hex 64 > $out/session-secret
        openssl rand -hex 64 > $out/storage-encryption-key
        openssl rand -hex 64 > $out/oidc-hmac-secret
        openssl genrsa -out $out/oidc-jwks-key 4096
      '';
    };
  };

  # Resolve *File references in config JSON at service startup
  systemd.services."authelia-${inst}" = {
    preStart = lib.mkBefore ''
      ${lib.optionalString hasUsers ''
        ${pkgs.python3}/bin/python3 ${nix-to-config} ${usersConfigJson} /run/authelia-${inst}/users.json
      ''}
      ${lib.optionalString hasClients ''
        ${pkgs.python3}/bin/python3 ${nix-to-config} ${oidcConfigJson} /run/authelia-${inst}/oidc.json
      ''}
    '';
    serviceConfig.RuntimeDirectory = lib.mkDefault "authelia-${inst}";
  };

  services.authelia.instances.${inst} = {
    enable = true;

    secrets =
      with config.clan.core.vars.generators.authelia.files;
      {
        jwtSecretFile = jwt-secret.path;
        sessionSecretFile = session-secret.path;
        storageEncryptionKeyFile = storage-encryption-key.path;
      }
      // lib.optionalAttrs hasClients {
        oidcHmacSecretFile =
          config.clan.core.vars.generators.authelia.files.oidc-hmac-secret.path;
        oidcIssuerPrivateKeyFile =
          config.clan.core.vars.generators.authelia.files.oidc-jwks-key.path;
      };

    settingsFiles = lib.mkIf hasClients [
      "/run/authelia-${inst}/oidc.json"
    ];

    settings =
      {
        theme = settings.theme;

        webauthn = lib.mkIf settings.webauthn.enable {
          enable_passkey_login = true;
          selection_criteria = lib.mkIf settings.webauthn.requireDiscoverable {
            discoverability = "required";
          };
        };

        server.address = "tcp://127.0.0.1:${toString port}";

        log = {
          level = "info";
          format = "text";
        };

        authentication_backend = lib.mkIf hasUsers {
          file.path = "/run/authelia-${inst}/users.json";
          password_reset.disable = true;
          password_change.disable = true;
        };

        access_control = {
          default_policy = settings.defaultPolicy;
          rules =
            # User-specified rules (first-match, highest priority)
            settings.accessControlRules
            ++ [
              # Auto-generated: authelia settings page requires 2FA (passkey registration)
              {
                domain = settings.publicHost;
                resources = [ "^/settings.*$" ];
                policy = "two_factor";
              }
              # Auto-generated: all subdomains of the cookie domain default to one_factor
              {
                domain = "*.${settings.domain}";
                policy = "one_factor";
              }
            ];
        };

        session = {
          name = "authelia_session";
          cookies = map (c: {
            domain = c.domain;
            authelia_url = c.autheliaUrl;
          }) effectiveCookies;
        };

        storage.local.path = "/var/lib/authelia-${inst}/db.sqlite3";

        notifier = {
          filesystem = {
            filename = "/var/lib/authelia-${inst}/notifications.txt";
          };
        };
      }
      // settings.extraSettings;
  };

  # Reverse proxy via Caddy (always emitted)
  services.caddy = {
    enable = true;
    virtualHosts."${settings.publicHost}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString port}
      ${settings.caddy.extraConfig}
    '';
  };
}
