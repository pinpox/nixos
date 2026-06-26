{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
# Self-hosted Matrix homeserver (Synapse). `server_name` is `pinpox.com`, so
# accounts are `@<localpart>:pinpox.com` (the opencrow bots become
# `@opencrow_<instance>:pinpox.com`). The server itself is served at `host`
# (matrix.pinpox.com), TLS-terminated by Caddy on this machine; federation and
# client discovery for `pinpox.com` are delegated to `host` via the two
# /.well-known/matrix/* files — served on the `pinpox.com` apex (porree), not
# here, since that domain's web vhost lives there. Federation rides 443 (no
# 8448, no SRV records).
let
  cfg = config.pinpox.services.matrix-synapse;

  # Registration shared secret (a YAML fragment), generated once and merged
  # into the homeserver config via extraConfigFiles. With open registration
  # disabled, this is what lets `register_new_matrix_user` provision accounts
  # (one per bot, plus an admin). Deployed readable by the service user.
  regSecretFile =
    config.clan.core.vars.generators."matrix-registration-secret".files."registration_shared_secret.yaml".path;
in
{
  options.pinpox.services.matrix-synapse = {
    enable = mkEnableOption "Matrix Synapse homeserver";

    serverName = mkOption {
      type = types.str;
      default = "pinpox.com";
      description = ''
        The Matrix `server_name` — the domain part of every user/room ID
        (`@user:<serverName>`). PERMANENT: changing it invalidates all
        identities. Discovery/federation for this domain is delegated to
        `host` via /.well-known/matrix/* served on `<serverName>` itself.
      '';
    };

    host = mkOption {
      type = types.str;
      default = "matrix.pinpox.com";
      description = ''
        Public FQDN where Synapse is actually reachable (TLS-terminated by
        Caddy on this machine, Let's Encrypt). The /.well-known delegation on
        `serverName` points federation and clients here.
      '';
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Bot account localparts to ensure exist on this homeserver. Each gets an
        auto-generated password (clan vars) and is created non-admin,
        idempotently, by a oneshot after Synapse starts. Admin accounts are not
        managed here — create those by hand with register_new_matrix_user.
      '';
      example = [
        "opencrow_claude"
        "opencrow_local"
      ];
    };
  };

  config = mkIf cfg.enable {

    # Postgres backing store. Synapse REQUIRES the database to use `C`
    # collation/ctype; create the role + database explicitly with the right
    # locale on first cluster init (this machine has no prior postgres). Peer
    # auth maps the `matrix-synapse` system user to the same-named role over
    # the unix socket — no password. NOTE: initialScript runs only on a fresh
    # cluster; if postgres already exists, create the DB manually (see the SQL
    # in nixos/modules/services/matrix/synapse.md).
    services.postgresql = {
      enable = true;
      initialScript = pkgs.writeText "matrix-synapse-init.sql" ''
        CREATE ROLE "matrix-synapse" WITH LOGIN;
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      '';
    };

    clan.core.vars.generators = {
      "matrix-registration-secret" = {
        files."registration_shared_secret.yaml" = {
          secret = true;
          owner = "matrix-synapse";
          mode = "0400";
        };
        runtimeInputs = with pkgs; [
          coreutils
          openssl
        ];
        script = ''
          printf 'registration_shared_secret: "%s"\n' "$(openssl rand -hex 32)" \
            > "$out/registration_shared_secret.yaml"
        '';
      };
    }
    # One auto-generated password per declared bot account. Root-owned (the
    # reconciler runs as root); the bots never use it — they authenticate to
    # Matrix with an access token, not a password.
    // listToAttrs (
      map (
        name:
        nameValuePair "matrix-user-${name}" {
          files."password" = { };
          runtimeInputs = with pkgs; [
            coreutils
            openssl
          ];
          script = ''printf '%s' "$(openssl rand -hex 32)" > "$out/password"'';
        }
      ) cfg.users
    );

    systemd.services.matrix-synapse = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };

    # Idempotent reconciler: ensure each declared bot account exists once
    # Synapse is reachable. `--exists-ok` makes reruns no-ops; this only creates
    # accounts — it does not reset an existing account's password or flags.
    systemd.services.matrix-user-reconcile = mkIf (cfg.users != [ ]) {
      description = "Ensure declared Matrix bot accounts exist";
      after = [ "matrix-synapse.service" ];
      wants = [ "matrix-synapse.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [
        config.services.matrix-synapse.package
        pkgs.curl
      ];
      script = ''
        set -eu
        # Wait until Synapse accepts connections before registering.
        for _ in $(seq 1 60); do
          curl -sf http://localhost:8008/_matrix/client/versions >/dev/null && break
          sleep 2
        done
        ${concatMapStringsSep "\n" (name: ''
          register_new_matrix_user --exists-ok \
            -c ${regSecretFile} \
            -u ${escapeShellArg name} \
            --no-admin \
            --password-file ${config.clan.core.vars.generators."matrix-user-${name}".files."password".path} \
            http://localhost:8008
        '') cfg.users}
      '';
    };

    services.matrix-synapse = {
      enable = true;
      extraConfigFiles = [ regSecretFile ];
      settings = {
        server_name = cfg.serverName;
        public_baseurl = "https://${cfg.host}/";

        # Accounts are provisioned with the shared secret, never self-signup.
        enable_registration = false;

        # Open federation: you reach the bots from `@pinpox:matrix.org`. The
        # bots themselves only respond to that account (OPENCROW_ALLOWED_USERS),
        # so to shrink attack surface you may restrict the whole server to
        # federate ONLY with matrix.org by uncommenting:
        # federation_domain_whitelist = [ "matrix.org" "pinpox.com" ];

        database = {
          name = "psycopg2";
          args = {
            user = "matrix-synapse";
            database = "matrix-synapse";
          };
        };

        # Single internal listener; Caddy fronts it on 443 and forwards both
        # client and federation traffic.
        listeners = [
          {
            port = 8008;
            bind_addresses = [ "127.0.0.1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [
                  "client"
                  "federation"
                ];
                compress = true;
              }
            ];
          }
        ];
      };
    };

    # Public TLS endpoint + reverse proxy. This host serves only Synapse, so
    # everything proxies to the internal listener (Synapse 404s unknown paths).
    # Caddy auto-issues the Let's Encrypt cert for `host`.
    services.caddy.virtualHosts."${cfg.host}".extraConfig = ''
      reverse_proxy 127.0.0.1:8008
    '';
  };
}
