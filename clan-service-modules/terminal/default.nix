{ ... }:
{
  _class = "clan.service";
  manifest.name = "terminal";
  manifest.description = "Web-based collaborative terminal (ttyd + dtach) behind OIDC";
  manifest.readme = ''
    Browser terminal served by ttyd, gated by oauth2-proxy against Authelia (OIDC).

    Each URL `?arg=<id>` maps to a persistent, shareable dtach session running as
    a dedicated `collab` user: create a session, share the link, a coworker joins
    the same live shell. Sessions survive browser disconnects (not host reboots).
    Hitting the bare URL with no `?arg=` spawns a fresh random session.
  '';
  manifest.categories = [ "Development" ];
  manifest.exports.out = [
    "endpoints"
    "auth"
  ];

  roles.default = {
    description = "ttyd web terminal with dtach-persistent sessions, OIDC-gated via oauth2-proxy + Authelia.";

    interface =
      { lib, meta, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = "term.${meta.domain}";
            example = "term.example.com";
            description = "Public hostname for the web terminal (fronted by Caddy → oauth2-proxy).";
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      let
        # OIDC client secret generator, shared (share = true) between this
        # consumer host and the Authelia host. Declared with no ownership here
        # (= root); each host overrides ownership for the files it actually
        # reads. Produces:
        #   client_secret      raw secret (unused directly; baked into envfile)
        #   client_secret_hash argon2 hash for Authelia's client_secret_file
        #   envfile            oauth2-proxy env (client + cookie secret)
        # runtimeInputs are added per-host where pkgs is available (here via
        # terminal.nix, on the Authelia host by the authelia clan service).
        terminalOidcGenerator = {
          share = true;
          files.client_secret = { };
          files.client_secret_hash = { };
          files.envfile = { };
          script = ''
            mkdir -p $out
            CLIENT_SECRET=$(openssl rand -hex 32)
            COOKIE_SECRET=$(openssl rand -hex 16)
            printf '%s' "$CLIENT_SECRET" > $out/client_secret
            authelia crypto hash generate argon2 --password "$CLIENT_SECRET" \
              | sed 's/^Digest: //' > $out/client_secret_hash
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\nOAUTH2_PROXY_COOKIE_SECRET=%s\n' \
              "$CLIENT_SECRET" "$COOKIE_SECRET" > $out/envfile
          '';
        };
      in
      {
        exports = mkExports {
          endpoints.hosts = [ settings.domain ];

          # Auto-registers the "terminal" OIDC client in Authelia (require_pkce
          # defaults on, so oauth2-proxy sends S256). Access is governed by the
          # authelia clan service: add `terminal` to its clientAccess, or put
          # collaborators in a `terminal-users` group (the default policy).
          auth.client = {
            clientId = "terminal";
            clientName = "Terminal";
            redirectUris = [ "https://${settings.domain}/oauth2/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            public = false;
          };
          auth.varsGenerator = terminalOidcGenerator;
        };

        nixosModule = import ./terminal.nix { inherit settings terminalOidcGenerator; };
      };
  };
}
