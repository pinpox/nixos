{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.team-nats;
  useTls = cfg.tls.certFile != null;
  useOidc = cfg.oidc.enable;

  # Non-secret public key value of a clan-vars generator, newline-trimmed
  # for clean interpolation into nats config.
  pubOf = gen: lib.removeSuffix "\n" config.clan.core.vars.generators.${gen}.files.pub.value;

  # Admin listeners (client protocol, monitoring HTTP) bind to loopback —
  # they're for local hub-shell use (`nats account info`, `nats stream add`,
  # scraping /varz). The leaf listener is the only teammate-facing port.
  adminBind = "127.0.0.1";

  teammateType = types.submodule (
    { name, ... }:
    {
      options = {
        nkey = mkOption {
          type = types.strMatching "^U[A-Z0-9]{55}$";
          description = ''
            Public NKEY of this teammate's bridge user. Generated on their
            side with `nk -gen user -pubout`; they hand you the pubkey
            (the `U…` line) out-of-band — same trust model as SSH
            authorized_keys. The seed never leaves their machine.
          '';
          example = "UDEFLUGK7NDJ2N3FZNT4DD2736Z6PCWXWMBSCZGZIDT4U5GJYHPGDX2H";
        };
        allowPublish = mkOption {
          type = types.listOf types.str;
          defaultText = literalExpression ''[ "team.''${name}.>" ]'';
          default = [ "team.${name}.>" ];
          description = ''
            Subject patterns this teammate is allowed to publish. The
            default restricts them to their own `team.<name>.>` namespace
            — they cannot spoof another teammate, and they cannot pollute
            the team-wide `shared.>` namespace.

            Add `shared.<subspace>.>` explicitly for service identities
            (CI bots, release automation) so the publishing nkey
            unambiguously attributes the event to that service.
          '';
        };
        allowSubscribe = mkOption {
          type = types.listOf types.str;
          default = [
            "team.>"
            "shared.>"
            "_INBOX.>"
          ];
          description = ''
            Subject patterns this teammate is allowed to subscribe to.
            `_INBOX.>` is required for NATS request/reply replies.
          '';
        };
      };
    }
  );
in
{
  options.pinpox.services.team-nats = {
    enable = mkEnableOption "team NATS server (shared bus for federation via leaf nodes)";

    serverName = mkOption {
      type = types.str;
      default = "team-nats";
      description = "nats-server server name (visible in cluster/leaf metadata).";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/team-nats";
      description = "JetStream / nats-server data directory (must be under /var/lib/).";
    };

    ports = {
      client = mkOption {
        type = types.port;
        default = 4222;
        description = "Client protocol port (bound to loopback, admin only).";
      };
      leaf = mkOption {
        type = types.port;
        default = 7422;
        description = "Leaf-node accept port (public; teammates' bridges connect here).";
      };
      monitoring = mkOption {
        type = types.port;
        default = 8222;
        description = "Monitoring HTTP port (bound to loopback).";
      };
    };

    tls = {
      certFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to the TLS certificate (PEM) for the leaf listener. The
          module is agnostic about provenance — point this at a self-signed
          cert (clan-vars generator), a `security.acme` cert, or any other
          source. Loaded into the nats unit via systemd `LoadCredential`
          (read as root), so file ownership/permissions don't matter.

          `null` (default) disables TLS — the leaf listener is then
          PLAINTEXT and must only be reachable over a trusted network
          (e.g. a private mesh). For public exposure, set this.

          The certificate's SAN MUST include the hostname (or IP)
          teammates dial in their leaf remote URL.
        '';
        example = literalExpression ''config.clan.core.vars.generators.team-nats-cert.files.cert.path'';
      };
      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the TLS private key (PEM) for the leaf listener. Required when `certFile` is set.";
        example = literalExpression ''config.clan.core.vars.generators.team-nats-cert.files.key.path'';
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Open the leaf port (default 7422) in the firewall so external
        teammates can connect. Client (4222) and monitoring (8222) always
        bind to loopback and are never opened.
      '';
    };

    teammates = mkOption {
      type = types.attrsOf teammateType;
      default = { };
      description = ''
        Map of teammate name → their bridge user. Each becomes one NKEY
        user in the TEAM account with per-teammate subject ACLs. Add a
        teammate by pasting their bridge pubkey here; remove by deleting
        the entry and redeploying.
      '';
      example = literalExpression ''
        {
          pinpox = { nkey = "UDEF..."; };
          alice  = { nkey = "UXYZ..."; };
          ci-bot = { nkey = "UCIB..."; allowPublish = [ "shared.ci.>" ]; };
        }
      '';
    };

    oidc = {
      enable = mkEnableOption ''
        OIDC auth-callout. Authenticate clients AND leaf bridges by
        validating an OIDC token (e.g. a Gitea id_token) instead of static
        nkeys, so membership lives in the OIDC provider and adding/removing
        access never redeploys this server.

        CUTOVER WARNING: enabling auth_callout makes the callout authenticate
        EVERY connection — the static `teammates` nkeys, the local admin
        nkey, and even the system user are ignored. So turning this on
        requires the leaf side to present OIDC tokens too (the client/leaf
        phase), or existing nkey leaf bridges stop connecting. Off by default
      '';
      issuer = mkOption {
        type = types.str;
        default = "";
        example = "https://git.0cx.de";
        description = "OIDC issuer URL (discovery base; the callout fetches JWKS from here).";
      };
      audience = mkOption {
        type = types.str;
        default = "";
        description = "The OAuth client_id the id_token is issued for; validated as the JWT audience.";
      };
      requiredGroup = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          If set, the token must carry this value in its `groups` claim
          (e.g. a Gitea org/team). This is the membership gate; null means
          any valid token from the issuer is accepted.
        '';
      };
      usernameClaim = mkOption {
        type = types.str;
        default = "preferred_username";
        description = "Token claim used as `<user>` in the `team.<user>.>` namespace.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/var/lib/" cfg.dataDir;
        message = "pinpox.services.team-nats: dataDir must be under /var/lib/ (got: ${cfg.dataDir}). StateDirectory cannot manage paths elsewhere.";
      }
      {
        assertion = (cfg.tls.certFile == null) == (cfg.tls.keyFile == null);
        message = "pinpox.services.team-nats: set both tls.certFile and tls.keyFile, or neither.";
      }
      {
        assertion = !useOidc || (cfg.oidc.issuer != "" && cfg.oidc.audience != "");
        message = "pinpox.services.team-nats: oidc.enable requires oidc.issuer and oidc.audience.";
      }
    ];

    warnings = optional (!useTls) ''
      pinpox.services.team-nats: TLS is disabled (tls.certFile unset). The
      leaf listener on port ${toString cfg.ports.leaf} is PLAINTEXT. Only
      expose it over a trusted network.
    '';

    networking.firewall.allowedTCPPorts = optionals cfg.openFirewall [
      cfg.ports.leaf
    ];

    # Upstream services.nats only declares StateDirectory for the default
    # /var/lib/nats. Add our own for the custom dataDir, plus LoadCredential
    # for the TLS cert/key (read as root -> readable by the nats user
    # regardless of the source file's ownership).
    systemd.services.nats.serviceConfig = {
      StateDirectory = baseNameOf cfg.dataDir;
      StateDirectoryMode = "0750";
      LoadCredential = optionals useTls [
        "leaf-cert:${cfg.tls.certFile}"
        "leaf-key:${cfg.tls.keyFile}"
      ];
    };

    # Local nkeys for this hub's own admin + system principals. Seeds stay
    # on this host (share=false); pubkeys are interpolated into the accounts
    # block via clan-vars `.value`.
    clan.core.vars.generators.team-nats-admin = {
      share = false;
      files.seed = {
        secret = true;
        mode = "0440";
        owner = "nats";
      };
      files.pub.secret = false;
      runtimeInputs = with pkgs; [ nkeys ];
      script = ''
        nk -gen user -pubout > pair
        head -n1 pair > $out/seed
        tail -n1 pair > $out/pub
      '';
    };

    clan.core.vars.generators.team-nats-sys = {
      share = false;
      files.seed = {
        secret = true;
        mode = "0440";
        owner = "nats";
      };
      files.pub.secret = false;
      runtimeInputs = with pkgs; [ nkeys ];
      script = ''
        nk -gen user -pubout > pair
        head -n1 pair > $out/seed
        tail -n1 pair > $out/pub
      '';
    };

    # OIDC auth-callout identities (only when oidc.enable). The account key
    # signs the user JWTs the callout mints (its pubkey is auth_callout.issuer);
    # the xkey decrypts auth requests (its pubkey is auth_callout.xkey); the
    # conn key is the callout's own AUTH-account login. Seeds are read by the
    # callout via systemd LoadCredential; pubkeys go into the rendered config.
    clan.core.vars.generators.team-nats-callout-account = mkIf useOidc {
      share = false;
      files.seed = {
        secret = true;
        mode = "0400";
      };
      files.pub.secret = false;
      runtimeInputs = with pkgs; [ nkeys ];
      script = ''
        nk -gen account -pubout > pair
        head -n1 pair > $out/seed
        tail -n1 pair > $out/pub
      '';
    };
    clan.core.vars.generators.team-nats-callout-xkey = mkIf useOidc {
      share = false;
      files.seed = {
        secret = true;
        mode = "0400";
      };
      files.pub.secret = false;
      runtimeInputs = with pkgs; [ nkeys ];
      script = ''
        nk -gen curve -pubout > pair
        head -n1 pair > $out/seed
        tail -n1 pair > $out/pub
      '';
    };
    clan.core.vars.generators.team-nats-callout-conn = mkIf useOidc {
      share = false;
      files.seed = {
        secret = true;
        mode = "0400";
      };
      files.pub.secret = false;
      runtimeInputs = with pkgs; [ nkeys ];
      script = ''
        nk -gen user -pubout > pair
        head -n1 pair > $out/seed
        tail -n1 pair > $out/pub
      '';
    };

    services.nats = {
      enable = true;
      serverName = cfg.serverName;
      port = cfg.ports.client;
      jetstream = true;
      dataDir = cfg.dataDir;
      # The leaf TLS cert/key are runtime systemd credentials
      # (/run/credentials/...), absent at build time, so the upstream
      # `nats-server -t` build check can't open them. Skip it when TLS is on.
      validateConfig = !useTls;

      settings = {
        host = adminBind;
        http = "${adminBind}:${toString cfg.ports.monitoring}";

        leafnodes = {
          port = cfg.ports.leaf;
          host = "0.0.0.0";
          # Don't gossip our leaf connect URLs to remotes — otherwise a
          # connecting leaf learns our internal/loopback addresses and
          # tries to dial them (ending up at its own listener).
          no_advertise = true;
        } // optionalAttrs useTls {
          tls = {
            cert_file = "/run/credentials/nats.service/leaf-cert";
            key_file = "/run/credentials/nats.service/leaf-key";
            # Negotiate TLS before any plaintext protocol exchange (2.10+).
            handshake_first = true;
          };
        };

        accounts = {
          SYS.users = [
            { nkey = lib.removeSuffix "\n" config.clan.core.vars.generators.team-nats-sys.files.pub.value; }
          ];

          TEAM = {
            jetstream = true;
            users =
              (mapAttrsToList (_name: t: {
                inherit (t) nkey;
                permissions = {
                  publish.allow = t.allowPublish;
                  subscribe.allow = t.allowSubscribe;
                };
              }) cfg.teammates)
              ++ [
                { nkey = lib.removeSuffix "\n" config.clan.core.vars.generators.team-nats-admin.files.pub.value; }
              ];
          };
        } // optionalAttrs useOidc {
          # The callout's own login (AUTH account). Listed as an auth_users
          # below, so it's exempt from the callout it serves.
          AUTH.users = [ { nkey = pubOf "team-nats-callout-conn"; } ];
        };

        system_account = "SYS";
      } // optionalAttrs useOidc {
        # Delegate authentication of all other connections to the callout.
        authorization.auth_callout = {
          issuer = pubOf "team-nats-callout-account";
          account = "AUTH";
          auth_users = [ (pubOf "team-nats-callout-conn") ];
          xkey = pubOf "team-nats-callout-xkey";
        };
      };
    };

    # The auth-callout service: validates OIDC tokens and mints scoped user
    # JWTs. Connects to the local server as the AUTH user (conn nkey); reads
    # its three seeds from systemd credentials.
    systemd.services.nats-auth-callout = mkIf useOidc {
      description = "NATS auth-callout (OIDC identity -> scoped NATS user JWT)";
      after = [
        "nats.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      requires = [ "nats.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        RestartSec = 5;
        LoadCredential = [
          "account-seed:${config.clan.core.vars.generators.team-nats-callout-account.files.seed.path}"
          "xkey-seed:${config.clan.core.vars.generators.team-nats-callout-xkey.files.seed.path}"
          "conn-seed:${config.clan.core.vars.generators.team-nats-callout-conn.files.seed.path}"
        ];
        Environment = [
          "CALLOUT_NATS_URL=nats://${adminBind}:${toString cfg.ports.client}"
          "CALLOUT_ACCOUNT_SEED_FILE=%d/account-seed"
          "CALLOUT_XKEY_SEED_FILE=%d/xkey-seed"
          "CALLOUT_CONN_NKEY_SEED_FILE=%d/conn-seed"
          "CALLOUT_OIDC_ISSUER=${cfg.oidc.issuer}"
          "CALLOUT_OIDC_AUDIENCE=${cfg.oidc.audience}"
          "CALLOUT_TARGET_ACCOUNT=TEAM"
          "CALLOUT_USERNAME_CLAIM=${cfg.oidc.usernameClaim}"
        ]
        ++ optional (cfg.oidc.requiredGroup != null) "CALLOUT_REQUIRED_GROUP=${cfg.oidc.requiredGroup}";
        ExecStart = "${pkgs.nats-auth-callout}/bin/nats-auth-callout";
      };
    };
  };
}
