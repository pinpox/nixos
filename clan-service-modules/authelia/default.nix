{
  clanLib,
  lib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "authelia";
  manifest.description = "Self-hosted OIDC identity provider with access control";
  manifest.categories = [ "Network" ];
  manifest.readme = builtins.readFile ./README.md;
  manifest.exports.out = [ "endpoints" ];
  manifest.exports.inputs = [ "auth" ];

  roles.default = {
    description = "Authelia server (one per clan). Aggregates users from auth.user exports and OIDC clients from auth.client exports.";

    interface =
      { lib, ... }:
      {
        options = {
          publicHost = lib.mkOption {
            type = lib.types.str;
            example = "auth.example.com";
            description = "Public hostname for Authelia (TLS via Caddy ACME)";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 9091;
            description = "Local port Authelia listens on (always 127.0.0.1)";
          };

          theme = lib.mkOption {
            type = lib.types.enum [
              "light"
              "dark"
              "auto"
              "grey"
            ];
            default = "auto";
          };

          defaultPolicy = lib.mkOption {
            type = lib.types.enum [
              "deny"
              "one_factor"
              "two_factor"
              "bypass"
            ];
            default = "deny";
            description = "Fallback ACL policy when no rule matches";
          };

          webauthn = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            requireDiscoverable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Require passkeys (discoverable creds), not just 2FA keys";
            };
          };

          domain = lib.mkOption {
            type = lib.types.str;
            example = "pablo.tools";
            description = ''
              The parent domain for Authelia's session cookie. All services
              under *.<domain> share this cookie for SSO. Must contain at
              least one period (RFC 6265). publicHost must be a subdomain
              of this domain.
            '';
          };

          extraCookieDomains = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  domain = lib.mkOption { type = lib.types.str; };
                  autheliaUrl = lib.mkOption { type = lib.types.str; };
                };
              }
            );
            default = [ ];
            description = ''
              Additional cookie domains beyond the primary one derived from
              `domain` + `publicHost`. Only needed for multi-TLD setups.
            '';
          };

          accessControlRules = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "Authelia access_control rules (free-form, first-match wins)";
          };

          clientAccess = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            default = { };
            description = ''
              Restrict OIDC client access to specific users/groups. Keyed by
              client ID. Values are lists of Authelia subject strings
              ("user:alice", "group:admins", etc.). Clients not listed here
              use defaultClientPolicy (one_factor for any authenticated user).
            '';
            example = lib.literalExpression ''
              {
                grafana = [ "user:pinpox" ];
                prometheus = [ "user:pinpox" ];
              }
            '';
          };

          clientPolicies = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
            description = ''
              Escape hatch: raw Authelia authorization policies keyed by
              "$\{clientId}-policy". Takes precedence over clientAccess and
              defaultClientPolicy for the same client ID.
            '';
          };

          extraClients = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
            description = ''
              OIDC clients defined inline, keyed by client ID. The key becomes
              client_id automatically. Use for consumers that don't export
              auth.client (e.g. non-clan-service NixOS modules). For
              clan-service consumers, prefer exporting auth.client from the
              consuming role's perInstance.
            '';
            example = lib.literalExpression ''
              {
                miniflux = {
                  redirect_uris = [ "https://news.example.com/oauth2/oidc/callback" ];
                  scopes = [ "openid" "profile" "email" ];
                };
              }
            '';
          };

          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Merged into services.authelia.instances.main.settings";
          };

          caddy.extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Extra Caddyfile directives for the Authelia vhost";
          };
        };
      };

    perInstance =
      {
        settings,
        exports,
        mkExports,
        instanceName,
        ...
      }:
      let
        allAuthExports = clanLib.selectExports (_scope: true) exports;

        # Single pass over all auth exports: collect users, clients, and
        # vars generators in one fold.
        extracted = lib.foldlAttrs (
          acc: _key: scope:
          let
            # auth.users is keyed by IdP instance name — pick only ours
            u = (scope.auth.users or { }).${instanceName} or null;
            c = scope.auth.client or null;
            gen = scope.auth.varsGenerator or null;
          in
          {
            users = acc.users ++ lib.optionals (u != null) [ u ];
            clients = acc.clients ++ lib.optionals (c != null) [ c ];
            varsGenerators =
              acc.varsGenerators
              // lib.optionalAttrs (c != null && gen != null && !(c.public or false)) {
                "authelia-oidc-${c.clientId}" = gen;
              };
          }
        ) {
          users = [ ];
          clients = [ ];
          varsGenerators = { };
        } allAuthExports;

        inherit (extracted) users clients varsGenerators;
      in
      {
        exports = mkExports {
          endpoints.hosts = [ settings.publicHost ];
        };

        nixosModule = import ./module.nix {
          inherit settings instanceName;
          exportedUsers = extracted.users;
          exportedClients = extracted.clients;
          exportedVarsGenerators = extracted.varsGenerators;
        };
      };
  };
}
