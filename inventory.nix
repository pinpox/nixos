{ self }:
{
  machines = {
    mango.tags = [ "desktop" ];
    kiwi.tags = [ "desktop" ];
    tanne.tags = [ "desktop" ];
    fichte.tags = [ "desktop" ];
    kartoffel.tags = [ "desktop" ];
    limette.tags = [ "desktop" ];
    linse.tags = [ "desktop" ];
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

    thelounge = {
      module.input = "self";
      module.name = "@pinpox/thelounge";
      roles.default.machines.kfbox = { };
    };

    tangled = {
      module.input = "self";
      module.name = "@pinpox/tangled";
      # Each must be verified once via the appview UI
      # (/settings/knots, /settings/spindles).
      roles.knot.machines.clementine.settings.host = "knot.pablo.tools";
      # roles.spindle.machines.clementine.settings.host = "spindle.pablo.tools";
    };

    # Personal event firehose. kfbox runs the broker; it authorizes a set of
    # public keys (seeds live with whoever runs each identity). Every machine
    # is a client (CLI + the human `pinpox` login key).
    nats = {
      module.input = "self";
      module.name = "@pinpox/nats";

      roles.server.machines.kfbox.settings.host = "nats.pin";

      # Pure authorizer: each entry = a pubkey (by generator) + allowed
      # topics. No seeds on the broker.
      roles.server.settings.authorizations = {
        pinpox = {
          permissions = {
            publish.allow = [
              "personal.>"
              "team.pinpox.>"
              "project.>"
              "home.>"
              "user.pinpox.>"
            ];
            subscribe.allow = [ ">" ];
          };
        };
        host-reporter = {
          permissions.publish.allow = [ "host.*.status" ];
        };
        ssh-logger = {
          permissions.publish.allow = [ "host.*.ssh.>" ];
        };
        nixos-reporter = {
          permissions.publish.allow = [ "host.*.nixos.>" ];
        };
        home-sensors = {
          permissions.publish.allow = [ "home.>" ];
        };
        zulip-bridge = {
          permissions.publish.allow = [ "chat.io.geninf.zulip.>" ];
        };
      };

      # Every machine is a client: nats CLI + NATS_URL + the human pinpox
      # login seed (owned by the pinpox login). Harmless on the server itself.
      roles.client.tags.all = { };
      roles.client.settings.loginUsers.pinpox = { };
    };

    # NATS ingestion workloads — one role per integration. Each role owns its
    # NKEY (declares the generator; seed only on its machine) and is authorized
    # by the matching `authorizations` entry above.
    nats-integrations = {
      module.input = "self";
      module.name = "@pinpox/nats-integrations";

      # Boot/clean-shutdown state from every machine → host.<hostname>.status (state in payload).
      roles.host-reporter.tags.all = { };

      # SSH auth events from every machine → host.<hostname>.ssh.<event>.
      roles.ssh-logger.tags.all = { };

      # NixOS generation activations (rebuilds) → host.<hostname>.nixos.activated.
      roles.nixos-reporter.tags.all = { };

      # Study ESPHome sensor → home.rooms.study.*  (traube only).
      roles.sensor-poller.machines.traube.settings = {
        sensorUrl = "http://192.168.101.103";
        interval = "5min";
        metrics = {
          "temp-02" = {
            subject = "home.rooms.study.temperature";
            unit = "°C";
          };
          "ccs811_eco2_value" = {
            subject = "home.rooms.study.co2";
            unit = "ppm";
          };
        };
      };

      # Zulip feed → chat.io.geninf.zulip.*  (kfbox only).
      roles.zulip-bridge.machines.kfbox.settings = {
        subjectRoot = "chat.io.geninf.zulip";
        includeDms = true;
      };

	  # Userspaces integrations
      # MPRIS playback (play/pause/track) → user.pinpox.music
      roles.user-music-status.tags.desktop = { };
    };

    # OpenCrow bot instances — one omp agent each, sandboxed container on
    # porree. The instance NAME is the container/state dir
    # (/var/lib/opencrow-<name>); keep "claude"/"local" so existing session
    # state and the mail-watcher path (modules/opencrow) stay valid. Per-
    # instance + shared secrets live in modules/opencrow, referenced by name.
    claude = {
      module.input = "self";
      module.name = "@pinpox/opencrow";
      roles.default.machines.porree.settings = {
        environment = {
          NEXTCLOUD_URL = "https://files.pablo.tools";
          NEXTCLOUD_USER = "pinpox";
          NEXTCLOUD_CALENDAR = "personal";
          WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
          WORK_NEXTCLOUD_USER = "pinpox";
          WORK_NEXTCLOUD_CALENDAR = "personal";
          OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
          OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
          OPENCROW_HEARTBEAT_INTERVAL = "30m";
        };
        environmentFileGenerators = [
          "opencrow"
          "opencrow-nextcloud"
          "opencrow-nextcloud-work"
          "opencrow-eversports"
        ];
      };
    };

    local = {
      module.input = "self";
      module.name = "@pinpox/opencrow";
      roles.default.machines.porree.settings = {
        environment = {
          NEXTCLOUD_URL = "https://files.pablo.tools";
          NEXTCLOUD_USER = "pinpox";
          NEXTCLOUD_CALENDAR = "personal";
          WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
          WORK_NEXTCLOUD_USER = "pinpox";
          WORK_NEXTCLOUD_CALENDAR = "personal";
          OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
          OPENCROW_MATRIX_USER_ID = "@c.h.i.m.p.:matrix.org";
          OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
          OPENCROW_PI_PROVIDER = "ollama";
          OPENCROW_PI_MODEL = "gemma4:26b";
          OPENCROW_PI_IDLE_TIMEOUT = "12h";
          OPENCROW_HEARTBEAT_INTERVAL = "30m";
          OPENCROW_LOG_LEVEL = "debug";
        };
        environmentFileGenerators = [
          "opencrow-local"
          "opencrow-nextcloud"
          "opencrow-nextcloud-work"
          "opencrow-eversports"
        ];
        piModels = {
          providers.ollama = {
            baseUrl = "http://100.96.100.103:11434/v1";
            api = "openai-completions";
            apiKey = "dummy";
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
            };
            models = [
              {
                id = "gemma4:26b";
                reasoning = true;
              }
            ];
          };
        };
      };
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
    # dm-pull-deploy = {
    #   module.input = "clan-community";
    #   module.name = "dm-pull-deploy";
    #   roles.push.machines.kiwi.settings.gitUrl = "https://github.com/pinpox/nixos.git";
    #   roles.default.tags = [ "all" ];
    #
    #   roles.default.machines.tanne.settings.action = "build";
    #   roles.default.machines.kiwi.settings.action = "switch";
    # };

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

    pi = {
      module.input = "spaces";
      module.name = "pi";

      # Kiwi is both a client (the chat panel) and an executor (its own
      # local pi-sessiond on loopback).
      roles.client.machines.kiwi = { };
      roles.executor.machines.kiwi.settings = {
        openrouter.enable = true;
        # PWA at https://agent-kiwi.pin/ (auto-derived clan host, exported
        # via the role's endpoints output → pki + dm-dns auto-issue cert +
        # CNAME, so it's reachable from any clan client without /etc/hosts
        # surgery).
        webUi.enable = true;
        llamaSwap.webUi.enable = true;
        llamaSwap.openFirewall = true;
      };

      # Tanne is only a client (no executor)
      roles.client.machines.tanne = { };

      # Traube is executor-only (tiny model, only for testing). Also hosts
      # the pi-web PWA at https://agent-traube.pin/ — the auto-derived
      # `agent-<machineName>.<meta.domain>` host, exported via the role's
      # endpoints output so pki/dm-dns auto-issue the cert + CNAME.

      roles.executor.machines.mango.settings = {
        defaultModel = "gemma4:12b-q8_0";
        webUi.enable = true;
        # Reachable at https://llama-swap.mango.pin/ (UI at /ui/), the
        # auto-derived `llama-swap.<machineName>.<meta.domain>` host —
        # exported via the role's endpoints output so pki/dm-dns
        # auto-issue the cert + CNAME.
        llamaSwap.webUi.enable = true;
        llamaSwap.openFirewall = true;
      };

      roles.executor.machines.traube.settings = {
        defaultModel = "qwen2.5:0.5b";
        webUi.enable = true;
        llamaSwap.openFirewall = true;
      };
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

      # "10.100.0.0/24"
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
