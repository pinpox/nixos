{ self, lib }:
let
  # Auto-merge instance fragments from ./inventory/*.nix (`_`-prefixed skipped),
  # deep-merged so several fragments can extend the same instance. Each is called
  # with `{ self, lib, ... }`.
  externalInstances =
    if builtins.pathExists ./inventory then
      builtins.foldl'
        (
          acc: f:
          lib.recursiveUpdate acc (
            import (./inventory + "/${f}") {
              inherit self lib;
            }
          )
        )
        { }
        (
          builtins.filter (n: builtins.substring 0 1 n != "_" && builtins.match ".*[.]nix" n != null) (
            builtins.attrNames (builtins.readDir ./inventory)
          )
        )
    else
      { };
in
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

  instances = lib.recursiveUpdate {

    # Matrix homeserver. Bot accounts are contributed next to the bots in
    # inventory/opencrow.nix and deep-merged in.
    matrix = {
      module.input = "self";
      module.name = "@pinpox/matrix";
      roles.server.machines.clementine = { };
    };

    incus = {
      module.input = "self";
      module.name = "@pinpox/incus";
      roles.peer.machines.mango.settings = {
        # Attach instances to the home LAN
        lanInterface = "enp191s0";
        # NixOS VM images imported as local:<name>. Value = the attribute name
        # of a `packages.<system>` entry built by pkgs.mkIncusVmImage (sshd +
        # keys baked in); `incus launch local:nixos-unstable-cloud-init foo --vm`
        # is SSH-reachable out of the box. `default` is a second alias for the
        # same image so `incus launch default foo --vm` works and it reads as
        # the default in the web UI. Referenced by name, not by value, so no
        # clan evaluation ever instantiates the image derivation. Add custom
        # ones to flake.nix `packages` via `pkgs.mkIncusVmImage { modules = [...]; }`.
        localImages.nixos-unstable-cloud-init = "incus-nixos-unstable-cloud-init";
        localImages.default = "incus-nixos-unstable-cloud-init";
        webui = {
          enable = true;
          host = "boxes.pin";
        };
      };
    };

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

    vikunja = {
      module.input = "self";
      module.name = "@pinpox/vikunja";
      # Public host so it's reachable from mobile; access is still gated by
      # Pocket ID OIDC (Vikunja's local login is disabled in the module).
      roles.default.machines.porree.settings.host = "todo.pablo.tools";
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
      };
      roles.default.extraModules = [ ./users/pinpox.nix ];
    };

    user-lislon = {
      module.name = "users";
      roles.default.machines.fichte = { };
      roles.default.settings = {
        user = "lislon";
        share = true;
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

    pocket-id = {
      module.input = "clan-community";
      module.name = "pocket-id";

      roles.default.extraModules = [
        (
          { config, ... }:
          {
            clan.core.vars.generators."pocket-id-smtp" = {
              files."smtp-password" = { };
              prompts."smtp-password" = {
                type = "hidden";
                persist = true;
                description = "Mail password for pocket-id@pinpox.com";
              };
            };
            services.pocket-id.credentials.SMTP_PASSWORD =
              config.clan.core.vars.generators."pocket-id-smtp".files."smtp-password".path;
          }
        )
      ];
      roles.default.machines.porree.settings = {
        publicHost = "id.pablo.tools";

        # Vikunja's OIDC client can't do PKCE yet (go-vikunja/vikunja#1501),
        # so exempt it from the reconciler's default PKCE requirement.
        pkceExemptClients = [ "vikunja" ];

        extraSettings = {
          UI_CONFIG_DISABLED = "true"; # Required for mail
          SMTP_HOST = "mail.pinpox.com";
          SMTP_PORT = "465";
          SMTP_TLS = "tls";
          SMTP_USER = "pocket-id@pinpox.com";
          SMTP_FROM = "pocket-id@pinpox.com";
          EMAIL_LOGIN_NOTIFICATION_ENABLED = "false";
          EMAIL_API_KEY_EXPIRATION_ENABLED = "true";
        };

        extraClients = {

          miniflux = {
            name = "Miniflux";
            isPublic = true;
            callbackURLs = [ "https://news.0cx.de/oauth2/oidc/callback" ];
          };

          incus = {
            name = "Incus";
            isPublic = true;
            pkceEnabled = false;
            callbackURLs = [ "https://boxes.pin/oidc/callback" ];
          };

          # Manual in PocketID: Create a "mail" group, add the users who should
          # have mailboxes, then set this client's "Allowed User Groups" to "mail"
          bulwark = {
            name = "Bulwark Webmail";
            isPublic = true;
            callbackURLs = [
              "https://webmail.pinpox.com/auth/callback"
              "https://webmail.pinpox.com/en/auth/callback"
            ];
          };

          # Stalwart's own web UI (self-service portal at
          # https://mail.pinpox.com/account/, admin dashboard at /admin/). The
          # client id is HARDCODED in Stalwart's WebUI bundle as
          # "stalwart-webui", so this attribute name must match exactly.
          # Without it an OIDC-backed account entering its address on the
          # Stalwart login page gets "The requested OAuth 2.0 Client does not
          # exist" from Pocket ID - which is what stops users from managing
          # their own app passwords. Separate from the `bulwark` client above
          # (that one works); public client + PKCE (S256), same shape.
          stalwart-webui = {
            name = "Stalwart Web UI";
            isPublic = true;
            callbackURLs = [
              "https://mail.pinpox.com/account/oauth/callback"
              "https://mail.pinpox.com/admin/oauth/callback"
              "https://mail.pinpox.com/oauth/callback"
            ];
          };
        };
      };
    };

    # Metrics + logs: clan-core push-based stack. Every machine runs an alloy
    # client shipping journal logs and node metrics to porree (mimir/loki);
    # grafana serves dashboards and evaluates the declarative alert rules.
    # The built-in nginx proxy is disabled; @pinpox/monitoring-glue provides
    # the caddy vhost, Pocket ID OIDC and the alert rules instead.
    monitoring = {
      module.input = "clan-core";
      module.name = "monitoring";

      roles.client = {
        tags.all = { };
        settings.useSSL = true;
        # vmstat/boottime/textfile collectors for the OOM/reboot/uptime and
        # flake-freshness alerts.
        extraModules = [ ./clan-service-modules/monitoring-glue/client-collectors.nix ];
      };

      roles.server.machines.porree.settings = {
        grafana.enable = true;
        host = "status.pin";
        proxy.enable = false;
        proxy.useSSL = true;
      };
    };

    # Caddy vhost (TLS via pki, DNS via dm-dns), Grafana OIDC client and
    # declarative alerting on the monitoring server.
    monitoring-glue = {
      module.input = "self";
      module.name = "@pinpox/monitoring-glue";
      roles.default.machines.porree = { };
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

    # Per-user Hermes agent MicroVMs. Replaces the old `pi` instance: spaces-os
    # deleted the whole pi tree (chat panel, pi-sessiond, pi-web) in favour of
    # hermes. The agents talk to the p0 inference endpoint, wired per machine.
    hermes = {
      module.input = "spaces";
      module.name = "hermes";

      # Hermes Micro VM
      roles.server.machines.traube = { };

      # Clients. Named machines, not tags.desktop: the client role covers
      # every isNormalUser on the machine it lands on, and traube serves
      # pinpox alone. fichte carries lislon, who would get a forwarded
      # port and an SSH key with no VM behind either.
      roles.client.machines.kiwi = { };

      # No extraSshOptions. The client role generates a hermes-only
      # keypair per user and pins ssh to it, so the forward never touches
      # the PIV token or the session agent. It could not use them anyway:
      # `ssh -o BatchMode=yes` from a systemd user unit cannot enter a
      # PIN.
      #
      # traube's sshd host key, pinned so kiwi's `ssh -o BatchMode=yes`
      # never needs trust-on-first-use — it cannot answer the prompt, so
      # an unknown key ends the launch. The role reads this from the
      # server's committed `openssh` var by default, but that var only
      # exists when clan-core's `sshd` or `admin` service runs on the
      # server, and neither does here.
      roles.client.settings.hostKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZmee1xtTuxlKNWYScLs8tq5ju73QKwI+jC3kx01HRi"
      ];
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
  } externalInstances;
}
