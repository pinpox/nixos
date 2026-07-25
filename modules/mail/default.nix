{
  config,
  pkgs,
  lib,
  nixpkgs-bulwark,
  nixpkgs-stalwart,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.mail;

  # Shared identity/hosts for the whole stack (Stalwart server + Bulwark webmail).
  # The mail host follows the primary domain (mail.<primaryDomain> / webmail.<...>),
  # so primaryDomain is the single knob that re-homes the whole stack.
  fqdn = "mail.${cfg.primaryDomain}"; # mail server hostname (cert CN / what clients connect to)
  webmailHost = "webmail.${cfg.primaryDomain}"; # Bulwark webmail vhost
  jmapUrl = "https://${fqdn}"; # Bulwark -> Stalwart JMAP endpoint
  issuerUrl = "https://id.pablo.tools"; # Pocket ID, shared OIDC issuer for server + webmail
  oidcClientId = "bulwark"; # Pocket ID public (PKCE) client id

  certDir = "/var/lib/acme/${fqdn}";
  dataDir = "/var/lib/stalwart";

  # Pinned to 0.16.13 via the `nixpkgs-stalwart` input, NOT our main nixpkgs:
  # 0.16.14 links jemalloc alongside the glibc-allocating librocksdb and SEGVs
  # in rocksdb's Arena on startup (see the input's comment in flake.nix). The
  # CLI is pinned from the same tree so its registry schema matches the server.
  pkg = nixpkgs-stalwart.legacyPackages.${pkgs.stdenv.hostPlatform.system}.stalwart_0_16;
  cli = nixpkgs-stalwart.legacyPackages.${pkgs.stdenv.hostPlatform.system}.stalwart-cli;

  # Port 80 vhost: answer the ACME HTTP-01 challenge for the mail-port cert
  # (lego) and redirect everything else to HTTPS.
  mailHttpConfig = ''
    handle /.well-known/acme-challenge/* {
      root * /var/lib/acme/acme-challenge
      file_server
    }
    handle {
      redir https://{host}{uri} permanent
    }
  '';

  # Mail-client autodiscovery vhosts. Stalwart already serves Mozilla autoconfig
  # (/mail/config-v1.1.xml and /.well-known/autoconfig/mail/config-v1.1.xml) plus
  # Microsoft Autodiscover (POST /autodiscover/autodiscover.xml) on its HTTP
  # listener - but clients probe autoconfig.<domain> / autodiscover.<domain>, so
  # without these vhosts they only ever get a TLS error. Caddy auto-issues the
  # certs (needs matching A/AAAA records per hosted domain).
  discoveryProxy = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:8080
  '';

  # Stalwart 0.16 keeps ONLY the data-store definition in its config file
  # (`--config`); everything else (listeners, TLS, directories, admin) lives in
  # the registry DB and is driven declaratively with `stalwart-cli apply` (see
  # the reconcile service). RocksDbStore has serde defaults for the rest.
  configFile = pkgs.writeText "stalwart-config.json" (
    builtins.toJSON {
      "@type" = "RocksDb";
      path = "${dataDir}/registry";
    }
  );

  # localId for a Domain's in-plan #reference (SystemSettings.defaultDomainId).
  # Upserts match on `name`, so this label only scopes the cross-reference.
  domId = name: "dom_" + replaceStrings [ "." "-" ] [ "_" "_" ] name;

  domainOp =
    name:
    let
      d = cfg.domains.${name};
    in
    {
      "@type" = "upsert";
      object = "Domain";
      matchOn = [ "name" ];
      value.${domId name} = {
        inherit name;
        isEnabled = true;
        # Static DKIM keys. The default is Automatic management, which rotates
        # every 90 days using date-based selectors (v1-rsa-<date>) - each
        # rotation would silently invalidate the DKIM TXT records published in
        # DNS and break outbound signing. Manual keeps the current keypair
        # (RSA + Ed25519) forever, so the DNS records stay valid.
        dkimManagement."@type" = "Manual";
      }
      // optionalAttrs (d.catchAll != null) { catchAllAddress = d.catchAll; }
      // optionalAttrs (d.aliases != [ ]) { aliases = d.aliases; };
    };

  # value-map key for an Account op (accounts aren't cross-referenced, so this
  # only needs to be unique + a valid attr name).
  acctId = name: "acct_" + replaceStrings [ "." "-" ] [ "_" "_" ] name;

  # Pre-create the OIDC user as a local principal that OWNS addresses in other
  # domains (send-as). Matched by its deterministic emailAddress (name@domain):
  # matchOn does NOT resolve #cross-refs, so we key on the email string, which
  # hits the OIDC-provisioned account (no duplicate). Alias sync is additive on
  # re-login, so this only adds the alias addresses. Each alias's domainId IS a
  # #<domId> cross-ref, which resolves inside the value. Only emitted when
  # aliasDomains is set.
  accountOp =
    name:
    let
      a = cfg.accounts.${name};
    in
    {
      "@type" = "upsert";
      object = "Account";
      matchOn = [ "emailAddress" ];
      value.${acctId name} = {
        "@type" = "User";
        emailAddress = "${name}@${a.domain}";
        inherit name;
        domainId = "#${domId a.domain}";
        roles."@type" = "User";
        aliases = listToAttrs (
          imap0 (i: d: {
            name = toString i;
            value = {
              enabled = true;
              inherit name;
              domainId = "#${domId d}";
            };
          }) a.aliasDomains
        );
      };
    };

  # Login-less send-only service account (<name>@<domain>) for an application
  # (SMTP submission on 465). Same idempotent shape as accountOp: upsert matched
  # on the deterministic emailAddress so re-apply is a no-op. No OIDC identity
  # and no interactive credential - the SMTP credential is an app-password
  # minted per app in the webadmin (its secret is server-generated and shown
  # once, so it cannot be provisioned declaratively).
  senderOp =
    name:
    let
      s = cfg.senders.${name};
    in
    {
      "@type" = "upsert";
      object = "Account";
      matchOn = [ "emailAddress" ];
      value.${acctId name} = {
        "@type" = "User";
        emailAddress = "${name}@${s.domain}";
        inherit name;
        domainId = "#${domId s.domain}";
        roles."@type" = "User";
      };
    };

  # Declarative registry config, applied with `stalwart-cli apply` (NDJSON, one
  # op per line). Idempotent: singletons use `update`, others `upsert` matched
  # on a stable scalar; `#localId` strings are cross-op references the server
  # resolves. NOTE: never set `proxyTrustedNetworks` here - in Stalwart that
  # enables the PROXY protocol (not X-Forwarded-For), which breaks Caddy's
  # plain-HTTP reverse proxy (empty replies).
  planLines = [
    # OIDC directory -> Pocket ID. `usernameDomain` (= primaryDomain) makes the
    # mailbox address <preferred_username>@<primaryDomain>, decoupled from the
    # IdP's email claim. requireAudience/requireScopes are explicitly nulled:
    # the object DEFAULTS requireAudience to "stalwart", but Pocket ID's
    # access-token `aud` is the client id ("bulwark") -> JWT `InvalidAudience`;
    # and its JWT carries no `scope` claim, so a non-empty requireScopes
    # rejects it. The token is still validated by JWKS signature + issuer + the
    # userinfo lookup.
    {
      "@type" = "upsert";
      object = "Directory";
      matchOn = [ "description" ];
      value.pocketid = {
        "@type" = "Oidc";
        description = "pocket-id";
        inherit issuerUrl;
        requireAudience = null;
        requireScopes = { };
        claimUsername = "preferred_username";
        usernameDomain = cfg.primaryDomain;
        claimName = "name";
        claimGroups = "groups";
      };
    }
  ]
  # One Domain per hosted domain (must exist before accounts / SystemSettings
  # reference it), each with its optional catch-all + alias domains.
  ++ map domainOp (attrNames cfg.domains)
  # Pre-created principals with cross-domain aliases (send-as), after the Domains
  # they reference. Only accounts that declare aliasDomains.
  ++ map accountOp (attrNames (filterAttrs (_: a: a.aliasDomains != [ ]) cfg.accounts))
  # Login-less send-only service accounts for applications (SMTP submission),
  # after the Domains they reference.
  ++ map senderOp (attrNames cfg.senders)
  ++ [
    # Delegate authentication to the OIDC directory.
    {
      "@type" = "update";
      object = "Authentication";
      value.directoryId = "#pocketid";
    }
    # HTTP server: allow the webmail's cross-origin JMAP calls
    # (usePermissiveCors) and read the real client IP from Caddy's
    # X-Forwarded-For (useXForwarded). This is the CORRECT forwarded-IP knob -
    # NOT proxyTrustedNetworks (PROXY protocol). Needs a settings reload (see
    # the reconcile ReloadSettings step).
    {
      "@type" = "update";
      object = "Http";
      value = {
        usePermissiveCors = true;
        useXForwarded = true;
      };
    }
  ];
  planFile = pkgs.writeText "stalwart-plan.ndjson" (
    concatMapStringsSep "\n" (l: builtins.toJSON l) planLines + "\n"
  );
in
{

  # Bulwark's NixOS module isn't in our pinned nixpkgs yet; pull it from the
  # pinned PR checkout (see flake input `nixpkgs-bulwark`). Imported on every
  # machine but inert unless services.bulwark.enable is set (below).
  imports = [
    "${nixpkgs-bulwark}/nixos/modules/services/web-apps/bulwark.nix"
  ];

  options.pinpox.services.mail = {
    enable = mkEnableOption "Stalwart 0.16 mail server (with Bulwark webmail)";

    webmail = mkOption {
      type = types.bool;
      default = true;
      description = "Serve the Bulwark webmail (JMAP client for Stalwart) on ${webmailHost}.";
    };

    primaryDomain = mkOption {
      type = types.str;
      default = "megaclan3000.de";
      description = ''
        Primary mail domain: used as the OIDC directory's usernameDomain (OIDC
        users whose username has no '@' become <username>@<primaryDomain>) and
        as SystemSettings.defaultDomainId. Must be a key in `domains`.
      '';
    };

    domains = mkOption {
      description = "Mail domains this server hosts, each with an optional catch-all and alias domains.";
      default = {
        "megaclan3000.de".catchAll = "pinpox@megaclan3000.de";
      };
      example = literalExpression ''
        {
          "megaclan3000.de".catchAll = "pinpox@megaclan3000.de";
          "lislon.example" = {
            catchAll = "lislon@lislon.example";
            aliases = [ "lislon.de" ];
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            catchAll = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Catch-all address receiving mail to unknown recipients in this domain.";
            };
            aliases = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Alias domain names that map onto this domain.";
            };
          };
        }
      );
    };

    accounts = mkOption {
      default = { };
      description = ''
        Local user principals to pre-create so one OIDC identity can OWN (send
        as) addresses in several domains. matchOn name+domainId hits the
        OIDC-provisioned account and aliases are additive, so this only adds the
        alias addresses; receiving is handled by the domains' catch-alls.
      '';
      example = literalExpression ''
        {
          pinpox = {
            domain = "megaclan3000.de";
            aliasDomains = [ "domain2.tld" "domain3.tld" ];
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            domain = mkOption {
              type = types.str;
              description = "Primary domain of the account (address is <name>@<domain>).";
            };
            aliasDomains = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Domains in which <name>@<domain> is an owned alias (send-as).";
            };
          };
        }
      );
    };

    senders = mkOption {
      default = { };
      description = ''
        Login-less send-only service accounts for applications (SMTP submission
        on 465). Each becomes a local principal <name>@<domain> with no OIDC
        identity and no interactive login. The SMTP credential is an app-password
        minted per app in the webadmin (admin -> the account -> app passwords):
        its secret is server-generated and shown only once, so it cannot be
        provisioned declaratively - copy it into the consuming app's own secret.
      '';
      example = literalExpression ''
        {
          notifications = { }; # notifications@<primaryDomain>
          ci.domain = "megaclan3000.de";
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            domain = mkOption {
              type = types.str;
              default = cfg.primaryDomain;
              description = "Domain of the sender address (<name>@<domain>); must be a hosted domain.";
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = hasAttr cfg.primaryDomain cfg.domains;
          message = "pinpox.services.mail.primaryDomain (\"${cfg.primaryDomain}\") must be one of the configured domains: ${concatStringsSep ", " (attrNames cfg.domains)}.";
        }
        {
          assertion = all (s: hasAttr s.domain cfg.domains) (attrValues cfg.senders);
          message = "Every pinpox.services.mail.senders.<name>.domain must be one of the configured domains: ${concatStringsSep ", " (attrNames cfg.domains)}.";
        }
      ];

      # Certificate for the MAIL protocol ports (SMTP/IMAP), obtained by lego via
      # HTTP-01 (challenge served by Caddy on :80) and consumed by Stalwart. The
      # web UI/JMAP is fronted by Caddy, which manages its OWN cert (below), so
      # Caddy never depends on this cert -> no bootstrap deadlock.
      security.acme.certs.${fqdn} = {
        webroot = "/var/lib/acme/acme-challenge";
        reloadServices = [ "stalwart.service" ];
      };

      services.caddy.virtualHosts = {
        # lego HTTP-01 responder + HTTPS redirect.
        "http://${fqdn}".extraConfig = mailHttpConfig;

        # Reverse proxy for JMAP + web admin on standard 443. Caddy terminates
        # TLS and forwards plain HTTP to Stalwart's loopback HTTP listener. Caddy
        # auto-issues its own cert via TLS-ALPN; disabling the HTTP challenge
        # keeps it off the :80 path lego uses for the mail-port cert above.
        "${fqdn}".extraConfig = ''
          tls {
            issuer acme {
              disable_http_challenge
            }
          }
          encode zstd gzip
          reverse_proxy 127.0.0.1:8080
        '';
      }
      # One autoconfig/autodiscover vhost pair per hosted domain, so entering an
      # address on a phone or in Thunderbird finds the settings automatically.
      // listToAttrs (
        concatMap (d: [
          {
            name = "autoconfig.${d}";
            value.extraConfig = discoveryProxy;
          }
          {
            name = "autodiscover.${d}";
            value.extraConfig = discoveryProxy;
          }
        ]) (attrNames cfg.domains)
      );

      # Fallback administrator (STALWART_RECOVERY_ADMIN=admin:<pw>). In 0.16 this
      # is a valid Basic-auth login in normal operation, used by the reconciler to
      # talk to the admin API and by us to reach the web admin. A random
      # passphrase is generated; the plaintext is kept for login, plus a ready
      # EnvironmentFile line for the service.
      clan.core.vars.generators."stalwart-admin" = {
        files."password" = { };
        files."recovery-env" = { };
        runtimeInputs = with pkgs; [
          coreutils
          xkcdpass
        ];
        script = ''
          pw=$(xkcdpass --numwords 5 --delimiter - --count 1)
          printf '%s' "$pw" > "$out"/password
          printf 'STALWART_RECOVERY_ADMIN=admin:%s\n' "$pw" > "$out"/recovery-env
        '';
      };

      # This service stores a potentially large amount of data, so a static user
      # (not DynamicUser) avoids re-chowning the store on every restart.
      users.users.stalwart = {
        isSystemUser = true;
        group = "stalwart";
      };
      users.groups.stalwart = { };

      # Only the mail protocol ports are exposed. JMAP + web admin are reached
      # through Caddy (https://${fqdn}) -> loopback HTTP listener (:8080). These
      # match the listeners Stalwart seeds by default (implicit TLS); STARTTLS
      # ports (587/143) are intentionally omitted.
      networking.firewall.allowedTCPPorts = [
        25 # SMTP (inbound)
        465 # submissions (implicit TLS)
        993 # IMAPS (implicit TLS)
      ];

      systemd.services.stalwart = {
        description = "Stalwart Server (0.16)";
        wantedBy = [ "multi-user.target" ];
        after = [
          "local-fs.target"
          "network.target"
          "acme-${fqdn}.service"
        ];
        wants = [ "acme-${fqdn}.service" ];

        serviceConfig = {
          Type = "simple";
          LimitNOFILE = 65536;
          KillMode = "process";
          KillSignal = "SIGINT";
          Restart = "on-failure";
          RestartSec = 5;
          SyslogIdentifier = "stalwart";

          # RocksDB lives under the state dir; create it before first start.
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${dataDir}/registry";
          ExecStart = "${pkg}/bin/stalwart --config=${configFile}";

          # Fallback-admin credential (read by PID1 before privilege drop).
          EnvironmentFile = config.clan.core.vars.generators."stalwart-admin".files."recovery-env".path;

          # Mail-port TLS cert as systemd credentials: loaded by root before
          # privileges drop, so Stalwart needs no access to /var/lib/acme. The
          # Certificate registry object (reconciler) references these paths.
          LoadCredential = [
            "tls-cert:${certDir}/fullchain.pem"
            "tls-key:${certDir}/key.pem"
          ];

          StateDirectory = "stalwart";
          CacheDirectory = "stalwart";
          # Stalwart's default tracer writes to /var/log/stalwart; ProtectSystem
          # =strict makes that read-only, so without this the log silently goes
          # nowhere. LogsDirectory creates a writable /var/log/stalwart.
          LogsDirectory = "stalwart";

          User = "stalwart";
          Group = "stalwart";

          # Bind standard privileged ports
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

          # Hardening (mirrors nixpkgs services.stalwart)
          DeviceAllow = [ "" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateUsers = false; # incompatible with CAP_NET_BIND_SERVICE
          ProcSubset = "pid";
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      # Push the declarative registry config into the running server. 0.16 keeps
      # this state in the DB (not the config file), so we converge it with
      # `stalwart-cli apply` after startup. Idempotent; re-runs when the unit or
      # plan changes. Auth uses the fallback admin (STALWART_RECOVERY_ADMIN).
      #
      # The static plan (OIDC directory, domains, accounts, auth) is Nix-generated;
      # the mail-port TLS Certificate + SystemSettings are appended at runtime
      # because the cert carries validity dates read from the lego cert. All ops
      # go in ONE apply so the `#localId` cross-references (`#<domId>`, `#mailcert`,
      # `#pocketid`) resolve. The Certificate references the cert FILES via the
      # stalwart service's LoadCredential paths, so renewal only needs a restart.
      systemd.services.stalwart-reconcile = {
        description = "Reconcile Stalwart registry config";
        after = [ "stalwart.service" ];
        wants = [ "stalwart.service" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ planFile ];
        path = [
          cli
          pkgs.curl
          pkgs.openssl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for the HTTP admin listener to accept connections.
          for _ in $(seq 1 60); do
            curl -s -o /dev/null http://127.0.0.1:8080/ && break
            sleep 1
          done

          export STALWART_URL="http://127.0.0.1:8080"
          export STALWART_USER="admin"
          STALWART_PASSWORD="$(cat ${
            config.clan.core.vars.generators."stalwart-admin".files."password".path
          })"
          export STALWART_PASSWORD

          plan="$(mktemp)"
          cat ${planFile} > "$plan"

          # Server identity + default domain (defaultDomainId resolves the primary
          # Domain created above via its #<domId> cross-reference).
          jq -cn '{"@type":"update",object:"SystemSettings",value:{defaultHostname:"${fqdn}",defaultDomainId:"#${domId cfg.primaryDomain}"}}' >> "$plan"

          # Mail-port TLS certificate, referenced by file (the stalwart service's
          # LoadCredential paths) rather than embedded, so renewal only needs a
          # restart. Validity dates are read from the lego cert.
          c="${certDir}/cert.pem"
          if [ -r "$c" ]; then
            nb="$(date -u +%Y-%m-%dT%H:%M:%SZ -d "$(openssl x509 -startdate -noout -in "$c" | cut -d= -f2)")"
            na="$(date -u +%Y-%m-%dT%H:%M:%SZ -d "$(openssl x509 -enddate -noout -in "$c" | cut -d= -f2)")"
            iss="$(openssl x509 -issuer -noout -in "$c" | sed 's/^issuer=//')"
            jq -cn --arg nb "$nb" --arg na "$na" --arg iss "$iss" \
              '{"@type":"upsert",object:"Certificate",matchOn:["issuer"],value:{mailcert:{certificate:{"@type":"File",filePath:"/run/credentials/stalwart.service/tls-cert"},privateKey:{"@type":"File",filePath:"/run/credentials/stalwart.service/tls-key"},subjectAlternativeNames:{"${fqdn}":true},notValidBefore:$nb,notValidAfter:$na,issuer:$iss}}}' >> "$plan"
          fi

          stalwart-cli apply --file "$plan"
          rm -f "$plan"

          # Point the default TLS cert at our mail cert. Done as a second step with
          # the resolved id: Certificate has no comparable matchOn key, so a
          # #cross-reference is unreliable.
          if [ -r "$c" ]; then
            certid="$(stalwart-cli query Certificate --json 2>/dev/null \
              | jq -r 'select(.subjectAlternativeNames["${fqdn}"]) | .id' | head -n1)"
            if [ -n "$certid" ]; then
              jq -cn --arg id "$certid" '{"@type":"update",object:"SystemSettings",value:{defaultCertificateId:$id}}' \
                | stalwart-cli apply --stdin
            fi
          fi

          # Apply the config to the running server without a restart: some
          # settings (CORS, listeners, TLS) are only read on load. ReloadSettings
          # picks up the registry changes; ReloadTlsCertificates re-reads the cert
          # files (also covers renewal).
          printf '%s\n%s\n' \
            '{"@type":"create","object":"Action","value":{"a":{"@type":"ReloadSettings"}}}' \
            '{"@type":"create","object":"Action","value":{"a":{"@type":"ReloadTlsCertificates"}}}' \
            | stalwart-cli apply --stdin
        '';
      };

      # Admin CLI + the reconcile tool available in the shell.
      environment.systemPackages = [
        pkg
        cli
      ];
    }

    (mkIf cfg.webmail {
      services.bulwark = {
        enable = true;
        # Build the package from the PR checkout too (keeps the master-based build
        # isolated from our pinned pkgs).
        package = nixpkgs-bulwark.legacyPackages.${pkgs.stdenv.hostPlatform.system}.bulwark;

        # Loopback only; Caddy terminates TLS and reverse-proxies.
        hostname = "127.0.0.1";
        port = 3000;

        settings = {
          jmapServerUrl = jmapUrl;

          # OIDC-only login against Pocket ID. Bulwark runs the browser OAuth flow
          # (public + PKCE client, so no secret to distribute cross-host), obtains
          # a Pocket ID access token, and uses it via OAUTHBEARER against Stalwart's
          # JMAP - which validates it through the pocket-id OIDC directory.
          oauth = {
            enabled = true;
            only = true;
            inherit issuerUrl;
            clientId = oidcClientId;
          };
        };

        # Files (WebDAV file storage) is off: upstream warns large uploads can
        # destabilise Stalwart/RocksDB, and we don't use it. Calendars/contacts
        # (CalDAV/CardDAV) are unaffected.
        policies.features.filesEnabled = false;
      };

      # Bulwark encrypts its server-side "Stalwart auth context" cookie with
      # SESSION_SECRET. Without it that cookie is never written, so
      # POST /api/account/stalwart/jmap has no upstream credential and answers
      # 401 "Not authenticated" - which is exactly what breaks App Passwords and
      # API Keys under Settings > Security. Mail/calendar/contacts are unaffected
      # because those talk to Stalwart with the browser's own OIDC token.
      clan.core.vars.generators."bulwark-session" = {
        files."secret" = { };
        runtimeInputs = with pkgs; [
          coreutils
          openssl
        ];
        script = ''
          openssl rand -base64 32 | tr -d '\n' > "$out"/secret
        '';
      };

      # The unit runs DynamicUser + ProtectSystem=strict and bind-mounts only
      # /nix/store, so /run/secrets is invisible inside its namespace. Hand the
      # secret over as a systemd credential (read by PID1 as root, exposed to the
      # service user) and point Bulwark at it; SESSION_SECRET_FILE takes
      # precedence over the config.json lookup.
      systemd.services.bulwark = {
        serviceConfig.LoadCredential = [
          "session-secret:${config.clan.core.vars.generators."bulwark-session".files."secret".path}"
        ];
        environment.SESSION_SECRET_FILE = "/run/credentials/bulwark.service/session-secret";
      };

      # HTTPS reverse proxy; Caddy auto-issues the cert for this web-only host.
      # Needs a DNS A/AAAA record for ${webmailHost} pointing at this host.
      #
      # X-Forwarded-Proto split (works around a Next.js quirk, no app patch):
      # Bulwark's next-intl locale rewrite (/ -> /en) on PAGE routes builds an
      # absolute same-origin URL from the request scheme; with xfp=https Next then
      # proxies to its own PLAINTEXT loopback port over TLS -> EPROTO -> HTTP 500.
      # next-intl skips /api and /_next, so those never hit that path. And the
      # OAuth origin is built client-side (window.location) in the browser, so
      # page routes don't need a truthful server-side proto. So: keep xfp=https
      # only for /api/* (where OAuth server code reads it and there's no rewrite),
      # and force xfp=http elsewhere so the self-proxy stays plaintext.
      services.caddy.virtualHosts."${webmailHost}".extraConfig = ''
        encode zstd gzip
        @api path /api/*
        handle @api {
          reverse_proxy 127.0.0.1:3000
        }
        handle {
          reverse_proxy 127.0.0.1:3000 {
            header_up X-Forwarded-Proto http
          }
        }
      '';
    })
  ]);
}
