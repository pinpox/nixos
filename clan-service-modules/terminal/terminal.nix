{
  settings,
  terminalOidcGenerator,
}:
{
  lib,
  pkgs,
  config,
  ...
}:
let
  ttydPort = 7681;
  oauth2Port = 4180;

  # Private /30-ish veth link between host and the container's network
  # namespace. oauth2-proxy reaches ttyd at localAddress:ttydPort; the host
  # NATs localAddress out for egress (git, nix, …).
  hostAddress = "10.151.151.1";
  localAddress = "10.151.151.2";
in
{
  # OIDC client secret (host side). oauth2-proxy reads `envfile` directly, so it
  # must be owned by oauth2_proxy; the other files stay root-owned and unused
  # here. The Authelia host gets `client_secret_hash` from the same shared
  # generator (see default.nix). Stays on the host — the container has no part
  # in authentication.
  clan.core.vars.generators."authelia-oidc-terminal" = terminalOidcGenerator // {
    runtimeInputs = with pkgs; [
      coreutils
      openssl
      authelia
      gnused
    ];
    files = terminalOidcGenerator.files // {
      envfile = {
        owner = "oauth2_proxy";
        mode = "0400";
      };
    };
  };

  # Unprivileged systemd-nspawn container: ttyd, dtach and the collab shell all
  # live in here on their own root filesystem, so the collab user only ever sees
  # the container — never the host. privateUsers="pick" maps the container's
  # UIDs/GIDs into an unprivileged host range (even container-root is powerless
  # on the host); privateNetwork gives it an isolated netns reachable only over
  # the veth. State (incl. /home/collab) persists in /var/lib/nixos-containers.
  containers.term = {
    autoStart = true;
    privateUsers = "pick";
    privateNetwork = true;
    inherit hostAddress localAddress;

    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        # Map each ttyd connection's ?arg=<id> to a persistent, shareable dtach
        # session: same id -> same socket -> same live shell (collaboration);
        # no id -> a fresh random session. dtach holds the PTY open after the
        # browser disconnects, so sessions persist without tmux. Only $1 is
        # honoured (ttyd --url-arg could otherwise pass extra args) and the id
        # is stripped to [A-Za-z0-9_-].
        sessionWrapper = pkgs.writeShellApplication {
          name = "collab-session";
          runtimeInputs = with pkgs; [
            dtach
            coreutils
            bashInteractive
          ];
          text = ''
            if [ -z "''${1:-}" ]; then
              id="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8 || true)"
            else
              id="''${1//[^a-zA-Z0-9_-]/}"
            fi
            [ -n "$id" ] || id="session"
            exec dtach -A "/run/collab/''${id}.sock" -E -z -r winch \
              ${pkgs.bashInteractive}/bin/bash -l
          '';
        };
      in
      {
        system.stateVersion = "26.05";

        # Resolver for the collab shell's egress (host NATs the subnet out).
        networking.nameservers = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        # Only the web-terminal port, reachable from the host over the veth.
        networking.firewall.allowedTCPPorts = [ ttydPort ];

        # Dedicated, unprivileged user the shared sessions run as. Anyone who
        # clears the OIDC gate gets a live, writable shell as this user —
        # confined to the container.
        users.users.collab = {
          isNormalUser = true;
          description = "Shared collaborative web-terminal sessions";
        };
        users.groups.collab = { };

        # ttyd serves the xterm.js UI and runs the session wrapper per
        # connection. It binds all interfaces inside the private netns, so only
        # the host (via the veth) can reach it. --url-arg passes the session id
        # via ?arg=<id>; --writable makes the terminal interactive.
        systemd.services.ttyd-terminal = {
          description = "ttyd collaborative web terminal";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          # libwebsockets is built with -DLWS_WITH_PLUGINS=ON, so its libuv event
          # loop is a separate libwebsockets-evlib_uv.so that lws dlopen()s by
          # bare name. With nixpkgs' DT_RUNPATH that isn't found via ttyd's
          # rpath, so point the loader at the plugin dir (else ttyd dies with
          # "lws_create_context: failed to load evlib_uv").
          environment.LD_LIBRARY_PATH = "${pkgs.libwebsockets}/lib";
          serviceConfig = {
            ExecStart = lib.concatStringsSep " " [
              "${pkgs.ttyd}/bin/ttyd"
              "--writable"
              "--url-arg"
              "--port ${toString ttydPort}"
              "--ping-interval 30"
              "-t 'fontFamily=monospace, JetBrains Mono'"
              "${sessionWrapper}/bin/collab-session"
            ];
            User = "collab";
            Group = "collab";
            RuntimeDirectory = "collab"; # /run/collab for the dtach sockets
            RuntimeDirectoryMode = "0700";
            Restart = "always";
            RestartSec = "2s";
          };
        };
      };
  };

  # Masquerade the container's private subnet so the collab shell has egress.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-term" ];
    externalInterface = "ens3";
  };

  # oauth2-proxy (host) runs the OIDC flow against Authelia and only proxies
  # through to the container's ttyd once the user is authenticated and
  # authorized (terminal-policy in Authelia).
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = "terminal";
    keyFile = config.clan.core.vars.generators."authelia-oidc-terminal".files.envfile.path;
    oidcIssuerUrl = "https://auth.pablo.tools";
    redirectURL = "https://${settings.domain}/oauth2/callback";
    upstream = [ "http://${localAddress}:${toString ttydPort}" ];
    httpAddress = "http://127.0.0.1:${toString oauth2Port}";
    cookie.secure = true;
    cookie.refresh = "1h";
    email.domains = [ "*" ];
    setXauthrequest = true;
    reverseProxy = true;
    # oauth2-proxy binds 127.0.0.1 only; the sole client that can reach it is
    # Caddy on loopback. Trust just loopback for X-Forwarded-* headers.
    trustedProxyIP = [
      "127.0.0.1/32"
      "::1/128"
    ];
    extraConfig = {
      skip-provider-button = true;
      # Authelia registers this client with require_pkce = true.
      code-challenge-method = "S256";
    };
  };

  # oauth2-proxy does OIDC discovery against Authelia at startup and exits if it
  # can't reach the issuer (briefly true while Authelia restarts). Keep retrying
  # instead of tripping systemd's default start limit.
  systemd.services.oauth2-proxy = {
    serviceConfig.RestartSec = "5s";
    unitConfig.StartLimitIntervalSec = 0;
  };

  # Public TLS endpoint. term.pinpox.com is a public domain (not a clan .pin
  # host), so the pki clan service ignores it and Caddy auto-provisions a
  # Let's Encrypt cert once DNS points here.
  #
  # Bare URL (no ?arg=) -> 302 to a fresh random session id so the address bar
  # reflects the session and the link is shareable (HedgeDoc-style). The target
  # is absolute on purpose: a redirect starting with "/" is parsed by Caddy's
  # redir as a path matcher. {http.request.uuid} is a per-request UUID.
  services.caddy = {
    enable = true;
    virtualHosts."${settings.domain}".extraConfig = ''
      @bare {
        path /
        not query arg=*
      }
      handle @bare {
        redir "https://${settings.domain}/?arg={http.request.uuid}" 302
      }
      handle {
        reverse_proxy 127.0.0.1:${toString oauth2Port}
      }
    '';
  };
}
