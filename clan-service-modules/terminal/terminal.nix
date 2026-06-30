{
  settings,
  terminalOidcGenerator,
}:
{
  pkgs,
  config,
  flake-self,
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

  containers.term = {
    autoStart = true;
    privateUsers = "pick";
    privateNetwork = true;
    inherit hostAddress localAddress;

    config =
      {
        pkgs,
        lib,
        ...
      }:
      let
        socketDir = "/run/term/sockets";
        # Per ?arg=<id>: attach to (creating on first connect) a detached dtach
        # session at <socketDir>/<id>.sock running a login shell.
        sessionWrapper = pkgs.writeShellApplication {
          name = "collab-session";
          runtimeInputs = with pkgs; [
            dtach
            coreutils
          ];
          text = ''
            if [ -z "''${1:-}" ]; then
              id="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8 || true)"
            else
              id="''${1//[^a-zA-Z0-9_-]/}"
            fi
            [ -n "$id" ] || id="session"

            export TERM=xterm-256color
            exec dtach -A "${socketDir}/''${id}.sock" -E -z -r winch ${pkgs.bashInteractive}/bin/bash -l
          '';
        };
      in
      {
        system.stateVersion = "26.05";

        # Packages available in every session, built on the host at deploy time
        # and consumed from the shared read-only store. The container carries no
        # overlays of its own, so pull in the flake's default overlay to expose
        # custom packages like omp (oh-my-pi).
        nixpkgs.overlays = [ flake-self.overlays.default ];
        environment.systemPackages = with pkgs; [
          omp
        ];

        # Make `nix` + flakes usable in sessions. /nix/store here is a read-only
        # bind mount, so the container can't build itself — it delegates to THIS
        # host's nix-daemon over the bind-mounted socket (the host's allowed-users
        # lets vu-term-* connect). Caches/substituters are the host daemon's, so
        # nothing cache-related belongs here.
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        networking.useHostResolvConf = false;
        networking.nameservers = [
          "1.1.1.1"
          "9.9.9.9"
        ];

        networking.firewall.allowedTCPPorts = [ ttydPort ];

        # ICMP for the unprivileged collab user.
        boot.kernel.sysctl."net.ipv4.ping_group_range" = "0 65534";

        users = {
          users.collab = {
            isNormalUser = true;
            group = "collab";
            description = "Web-terminal user (ttyd + all dtach sessions)";
          };
          groups.collab = { };
        };

        # Rendezvous dir for the dtach sockets, writable by collab.
        systemd.tmpfiles.rules = [
          "d /run/term 0755 root root -"
          "d ${socketDir} 0700 collab collab -"
        ];

        systemd.services.ttyd-terminal = {
          description = "ttyd collaborative web terminal";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
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
            Restart = "always";
            RestartSec = "2s";
            # Keep sessions alive across ttyd restarts
            KillMode = "process";
          };
        };
      };
  };

  # The term container shares this host's /nix/store read-only and delegates all
  # nix operations to this host's daemon over the bind-mounted socket. Its users
  # appear here as nss-systemd virtual users (vu-term-<container-uid>); allow them
  # so flakes/builds/substitution work inside sessions (collab=1000 ->
  # vu-term-1000, root -> vu-term-0). They stay UNtrusted (trusted-users is
  # unchanged), so they only ever use this host's configured substituters.
  nix.settings.allowed-users = [
    "vu-term-0"
    "vu-term-1000"
  ];

  # Masquerade the container's private subnet so the collab shell has egress.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-term" ];
    externalInterface = "ens3";
  };

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
    # Trust just loopback for X-Forwarded-* headers.
    trustedProxyIP = [
      "127.0.0.1/32"
      "::1/128"
    ];
    extraConfig = {
      skip-provider-button = true;
      code-challenge-method = "S256";
    };
  };

  systemd.services.oauth2-proxy = {
    serviceConfig.RestartSec = "5s";
    unitConfig.StartLimitIntervalSec = 0;
  };

  # Bare URL (no ?arg=) -> 302 to a fresh random session id
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
