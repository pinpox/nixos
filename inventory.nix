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

    nostr = {
      module.input = "clan-community";
      module.name = "nostr";
      roles.relay.machines.kfbox = {
        settings.host = "nostr.0cx.de";
      };
      roles.groups-relay.machines.kfbox = {
        settings.host = "groups.0cx.de";
        settings.relayName = "0cx.de NIP-29 Groups";
        settings.relayDescription = "NIP-29 group chat relay for 0cx.de";
      };
    };

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

    importer = {
      module.name = "importer";
      roles.default.tags.all = { };
      # Import all modules from ./modules/<module-name> on all machines
      roles.default.extraModules = (map (m: ./modules + "/${m}") (builtins.attrNames self.nixosModules));
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
