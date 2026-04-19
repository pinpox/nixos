{ self }:
{
  machines = {
    kiwi.tags = [ "desktop" ];
    tanne.tags = [ "desktop" ];
    fichte.tags = [ "desktop" ];
    kartoffel.tags = [ "desktop" ];
    limette.tags = [ "desktop" ];
    uconsole.tags = [ "mobile" ];

    birne.tags = [ "server" ];
    clementine.tags = [ "server" ];
    kfbox.tags = [ "server" ];
    porree.tags = [ "server" ];
    traube.tags = [ "server" ];
  };

  meta.name = "pinpox-clan";

  # My clan's top-level domain. All my service shall be accessible from within
  # the clan at https://<service>.pin
  meta.domain = "pin";

  instances = {

    # A service, which exports a endpoint: "music"
    # The goal is to be able to access https://music.pin from everywhere in the
    # clan and reach the navidrome server
    navidrome = {
      module.input = "self";
      module.name = "@pinpox/navidrome";
      roles.default.machines.kfbox = {
        settings.host = "music.0cx.de";
        # settings.host = "music.pin";
      };
    };

    # nostr = {
    #   module.input = "clan-community";
    #   module.name = "opencrow";
    #   roles.default.machines.kiwi = { };
    #   roles.llm.machines.kiwi = { };
    #   roles.nostr-relay.machines.kiwi = { };
    # };

    # nostr = {
    #   module.input = "clan-community";
    #   module.name = "nostr";
    #   roles.relay.machines.kfbox = {
    #     settings.host = "nostr.0cx.de";
    #   };
    #   roles.groups-relay.machines.kfbox = {
    #     settings.host = "groups.0cx.de";
    #     settings.relayName = "0cx.de NIP-29 Groups";
    #     settings.relayDescription = "NIP-29 group chat relay for 0cx.de";
    #   };
    # };

    thelounge = {
      module.input = "self";
      module.name = "@pinpox/thelounge";
      roles.default.machines.kfbox = { };
    };

    # Collects all "endpoint" exports from all services and generates a file
    # with CNAME entries.
    # The dm-dns services has an export of type "dataMesher" which signals "I
    # want the file 'dns/cnames' to be distributed via data-mesher".
    dm-dns = {
      module.name = "dm-dns";
      roles.push.machines.kiwi = { };
      roles.default.tags = [ "all" ];
    };

    # Also collects all "endpoint" exports from all services and uses them to
    # set up PKI. Only generators are used, no step-ca or otherwise
    # centralized service. The architecture is:
    # - A clan-wide CA is created (shared generater with deploy = false)
    # - Each host in the clan with the role additionally gets a Host CA, which
    #   is signed by the Root CA (generator dependand on the root-ca, deployed
    #   on each host)
    # - Each endpoint gets a certificate, signed by the Host CA (generator
    #   dependant on the Host CA)
    # - All hosts trust the Clan-wide Root CA
    # With this, every host can just visit the endpoint and is presented with a
    # certificate that is automatically trusted, because there is a chain of
    # trust up to the Root CA. If a host adds a new service/endpoint no
    # re-deployment of other hosts is required.
    pki = {
      module.name = "pki";
      roles.default.tags = [ "all" ];
    };

    # Pull-based NixOS deployment via data-mesher. Push machines send a flake
    # ref, all machines rebuild themselves from it.
    dm-pull-deploy = {
      module.input = "clan-community";
      module.name = "dm-pull-deploy";
      roles.push.machines.kiwi.settings.gitUrl = "https://github.com/pinpox/nixos.git";
      roles.default.tags = [ "all" ];

      roles.default.machines.tanne.settings.action = "build";
    };

    # The actual data-mesher. It collects all exports of type "dataMesher" from
    # all services and configures itself to distribute the files accordingly.
    data-mesher = {
      roles.bootstrap.tags = [ "server" ];
      roles.default.tags = [ "all" ];
      roles.default.settings.interfaces = [ "ygg" ];
    };

    internet = {
      module.name = "internet";
      roles.default.tags = [ "server" ];
      roles.default.machines = {
        kfbox.settings.host = "46.38.242.17";
        porree.settings.host = "94.16.108.229";
        clementine.settings.host = "152.53.139.179";
      };
    };

    tor = {
      module.name = "tor";

      # Add all machines to tor
      # Add smokeping to test if yggdrasil uses the best way

      roles.client.machines.kiwi = { };
      roles.client.machines.porree = { };

      roles.server.machines = {

        kiwi.settings = {
          secretHostname = false;
          portMapping = [
            {
              port = 6443;
              target.port = 6443;
            }
            {
              port = 6446;
              target.port = 6446;
            }
          ];
        };

        porree.settings = {
          secretHostname = false;
          portMapping = [
            {
              port = 6443;
              target.port = 6443;
            }
            {
              port = 6446;
              target.port = 6446;
            }
          ];
        };
      };
    };

    yggdrasil = {
      module.name = "yggdrasil";
      roles.default.tags = [ "all" ];
    };

    desktop = {
      module.input = "clan-community";
      module.name = "desktop";
      roles.sway.tags.desktop = { };
      roles.kde.machines.fichte = { };
    };

    user-root = {
      module.name = "users";
      roles.default.tags.all = { };
      roles.default.settings = {
        user = "root";
        share = true;
        # no identity = no IdP account
      };
      roles.default.extraModules = [ ./users/root.nix ];
    };

    user-pinpox = {
      module.name = "users";
      roles.default.tags.all = { };
      roles.default.settings = {
        user = "pinpox";
        share = true;
        identity.main = {
          email = "mail@pablo.tools";
          groups = [
            "admins"
            "users"
            "miniflux-users"
            "opencloud-users"
            "paperless-users"
          ];
        };
      };
      roles.default.extraModules = [ ./users/pinpox.nix ];
    };

    # Identity-only user: IdP account but no Unix account
    user-berber = {
      module.name = "users";
      roles.default.tags.all = { };
      roles.default.settings = {
        user = "berber";
        systemUser = false;
        identity.main = {
          groups = [
            "users"
            "opencloud-users"
            "miniflux-users"
          ];
        };
      };
    };

    user-lislon = {
      module.name = "users";
      roles.default.machines.fichte = { };
      roles.default.settings = {
        user = "lislon";
        share = true;
        identity.main = { };
      };
    };

    localsend = {
      module.input = "clan-community";
      module.name = "localsend";
      roles.default.tags = [ "desktop" ];
    };

    machine-type = {
      module.input = "self";
      module.name = "@pinpox/machine-type";
      roles.desktop.tags.desktop = { };
      roles.server.tags.server = { };
      roles.mobile.tags.mobile = { };
    };

    main = {
      module.input = "clan-community";
      module.name = "authelia";
      roles.default.machines.porree.settings = {
        publicHost = "auth.pablo.tools";
        domain = "pablo.tools";

        # Additional ACL rules (prepended before the auto-generated wildcard)
        accessControlRules = [
          {
            domain = "paper.pablo.tools";
            policy = "one_factor";
            subject = "group:paperless-users";
          }
        ];

        # Restrict these clients to pinpox only.
        # Unlisted clients use the default: any authenticated user.
        clientAccess = {
          grafana = [ "user:pinpox" ];
          prometheus = [ "user:pinpox" ];
        };

        # OIDC clients for non-clan-service consumers (miniflux, forgejo,
        # opencloud are still NixOS modules, not clan services, so they
        # can't export auth.client themselves yet).
        extraClients = {
          miniflux = {
            redirect_uris = [ "https://news.0cx.de/oauth2/oidc/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            token_endpoint_auth_method = "client_secret_basic";
          };
          forgejo = {
            client_name = "Forgejo";
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [ "https://git.pinpox.com/user/oauth2/authelia/callback" ];
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            token_endpoint_auth_method = "client_secret_basic";
          };
          opencloud = {
            client_name = "OpenCloud";
            public = true;
            require_pkce = true;
            pkce_challenge_method = "S256";
            scopes = [
              "openid"
              "offline_access"
              "groups"
              "profile"
              "email"
            ];
            redirect_uris = [
              "https://cloud.pablo.tools/"
              "https://cloud.pablo.tools/oidc-callback.html"
              "https://cloud.pablo.tools/oidc-silent-redirect.html"
            ];
            response_types = [ "code" ];
            grant_types = [
              "authorization_code"
              "refresh_token"
            ];
            token_endpoint_auth_method = "none";
          };
        };
      };
    };

    punchcard1 = {
      module.input = "clan-community";
      module.name = "punchcard";
      roles.default.machines.clementine.settings = {
        publicHost = "punchcard.megaclan3000.de";
        environmentFile = "/run/secrets/punchcard/envfile";
      };
      roles.default.extraModules = [
        (
          { pinpox-utils, ... }:
          {
            clan.core.vars.generators."punchcard" = pinpox-utils.mkEnvGenerator [
              "OIDC_ISSUER_URL"
              "OIDC_CLIENT_ID"
              "OIDC_CLIENT_SECRET"
            ];
          }
        )
      ];
    };

    punchcard2 = {
      module.input = "clan-community";
      module.name = "punchcard";
      roles.default.machines.clementine.settings = {
        publicHost = "punchcard2.megaclan3000.de";
        port = 8100;
        environmentFile = "/run/secrets/punchcard2/envfile";
      };
      roles.default.extraModules = [
        (
          { pinpox-utils, ... }:
          {
            clan.core.vars.generators."punchcard2" = pinpox-utils.mkEnvGenerator [
              "OIDC_ISSUER_URL"
              "OIDC_CLIENT_ID"
              "OIDC_CLIENT_SECRET"
            ];
          }
        )
      ];
    };

    monitoring = {
      module.input = "self";
      module.name = "@pinpox/monitoring";

      # node-exporter on every host
      # roles.node-exporter.tags.all = { };
      #
      # # Centralized monitoring server lives on porree
      roles.prometheus.machines.porree.settings = {
        blackboxTargets = [
          "https://pablo.tools"
          # "https://megaclan3000.de"
          # "https://build.lounge.rocks"
          # "https://pass.pablo.tools" # Vaultwarden
          # "https://pinpox.github.io/nixos/"
          # "https://cache.lounge.rocks/nix-cache/nix-cache-info"
          # "https://news.0cx.de"
          # "https://git.0cx.de" # Gitea
          # "https://irc.0cx.de"
        ];
      };
      # roles.loki.machines.porree = { };

      roles.grafana.machines.porree.settings = {
        oidc = {
          enable = true;
          issuer = "https://auth.pablo.tools";
          clientId = "grafana";
        };
      };

      # roles.blackbox.machines.porree = { };
      # roles.alertmanager-irc-relay.machines.porree = { };
    };

    importer = {
      module.name = "importer";
      roles.default.tags.all = { };
      # Import all modules from ./modules/<module-name> on all machines
      roles.default.extraModules = (
        map (m: ./modules + "/${m}") (
          builtins.filter (m: m != "opencrow") (builtins.attrNames self.nixosModules)
        )
      );
    };

    zerotier = {
      roles.controller.machines.clementine = { };
      roles.peer.machines.kiwi = { };
      # roles.peer.tags.all = { };
    };

    wg-star = {

      module.input = "clan-community";
      module.name = "dm-wireguard-star";

      roles.controller.machines.porree.settings = {
        endpoint = "vpn.pablo.tools";
        listenPort = 51821;
      };

      roles.peer.machines.kiwi = { };
      roles.peer.machines.kfbox = { };
    };

    wg-clan = {

      module.input = "clan-community";
      module.name = "wireguard-star";

      roles.controller.machines.porree.settings = {
        endpoint = "vpn.pablo.tools:51820";
      };

      roles.peer.machines = {
        kartoffel = { };
        birne.settings.allowedIPs = [
          "10.100.0.0/24"
          "192.168.101.0/24"
        ];
        kfbox = { };
        uconsole = { };
        clementine = { };
        kiwi = { };
        limette = { };
      };
    };
  };
}
