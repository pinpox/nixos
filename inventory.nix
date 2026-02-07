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
    kfbox.tags = [ "server" ];
    porree.tags = [ "server" ];
  };

  meta.name = "pinpox-clan";
  meta.domain = "pin";

  instances = {

    # Also collects all "endpoint" exports from all services and uses them to
    # set up certificates. Only generators are used, no step-ca or otherwise
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
    certificates = {
      module.input = "self";
      module.name = "@pinpox/certificates";
      roles.default.tags = [ "all" ];
    };
    data-mesher = {

      roles.default.tags = [ "all" ];
      roles.default.settings = {
        interfaces = [ "ygg" ];
        bootstrapNodes = [
          # TODO set this to all machines with the default role
          "kiwi.pin"
          "tanne.pin"
          "kfbox.pin"
        ];
      };

      roles.default.extraModules = [
        (
          { config, pkgs, ... }:
          {
            clan.core.vars.generators.data-mesher-signing-key = {
              share = true;
              files = {
                "signing.key".deploy = false;
                "signing.pub".secret = false;
              };
              runtimeInputs = [ config.services.data-mesher.package ];
              script = ''
                data-mesher generate signing-key \
                  --private-key-path "$out/signing.key" \
                  --public-key-path "$out/signing.pub"
              '';
            };

            # TODO this config should be done via exports
            services.data-mesher.settings.files = {
              "test/shared" = [
                # TODO add other keys
                config.clan.core.vars.generators.data-mesher-signing-key.files."signing.pub".value
              ];
              "test/foo" = [
                config.clan.core.vars.generators.data-mesher-signing-key.files."signing.pub".value
              ];
            };

            environment.systemPackages =
              let
                dm-send = pkgs.writeShellApplication {
                  name = "dm-send";
                  runtimeInputs = [ config.services.data-mesher.package ];
                  text = ''
                    if [ $# -ne 2 ]; then
                      echo "Usage: dm-send <name> <file>"
                      exit 1
                    fi
                    data-mesher file update "$2" \
                      --url http://localhost:7331 \
                      --key "$(passage show clan-vars/shared/data-mesher-signing-key/signing.key)" \
                      --name "$1"
                  '';
                };
              in
              [ dm-send ];
          }
        )
      ];
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

      # ADD all mahines to tor
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

    # TODO: re-enable when merged
    # Add monitoring to the whole clan
    # monitoring = {
    #   module.name = "monitoring";
    #   # roles.telegraf.tags = [ "all" ];
    #   roles.telegraf.tags = [ "desktop" ];
    #   roles.prometheus.machines.kiwi = { };
    # };

    desktop = {
      module.input = "self";
      module.name = "@pinpox/desktop";
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
      module.input = "self";
      module.name = "@pinpox/localsend";
      roles.default.tags = [ "desktop" ];
    };

    navidrome = {
      module.input = "self";
      module.name = "@pinpox/navidrome";
      roles.default.machines.kfbox = {
        settings.host = "music.pin";
      };
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

    dns-mesher = {
      module.input = "self";
      module.name = "@pinpox/dns-mesher";
      roles.default.tags = [ "all" ];

      # roles.exampleservice.machines.porree = { settings.host = "hallowelt.pablo.tools"; };

      # roles.exampleservice.machines.kiwi = { settings.host = "something.pin"; };
      # roles.exampleservice.machines.tanne = {
      # settings.host = "testtwo.pin";
      # };
    };

    wg-clan = {

      module.input = "self";
      module.name = "@pinpox/wireguard";

      roles.controller.machines.porree.settings = {
        endpoint = "vpn.pablo.tools:51820";
      };

      roles.peer.machines = {
        kartoffel = { };
        birne.settings.extraIPs = [ "192.168.101.0/24" ];
        kfbox = { };
        uconsole = { };
        kiwi = { };
        limette = { };
      };
    };
  };
}
