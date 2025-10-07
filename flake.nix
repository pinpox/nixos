{
  description = "My machines";

  inputs = {

    khard.url = "github:lucc/khard";
    khard.inputs.nixpkgs.follows = "nixpkgs";

    gif-searcher.url = "github:pinpox/gif-searcher";
    gif-searcher.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    jitsi-matrix-presence.url = "github:pinpox/jitsi-matrix-presence";
    jitsi-matrix-presence.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "git+https://git.clan.lol/clan/clan-core";
    # clan-core.url = "git+https://git.clan.lol/clan/clan-core?rev=3aa7750265b4d2eeb5f7791b4205d247078cf670";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";

    # caddy-patched.url = "github:pinpox/nixos-caddy-patched";
    # caddy-patched.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable?shallow=1";

    nixpkgs-master.url = "github:nixos/nixpkgs/master?shallow=1";

    aoe-taunt-discord-bot.url = "github:pinpox/aoe-taunt-discord-bot";
    aoe-taunt-discord-bot.inputs.nixpkgs.follows = "nixpkgs";

    pinpox-keys = {
      url = "https://github.com/pinpox.keys";
      flake = false;
    };

    pinpox-neovim.url = "github:pinpox/pinpox-neovim";
    pinpox-neovim.inputs.nixpkgs.follows = "nixpkgs";

    radio.url = "github:pinpox/radio";
    radio.inputs.nixpkgs.follows = "nixpkgs";

    mc3000.url = "github:pinpox/mc3000";
    mc3000.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk/master";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    promterm.url = "github:pinpox/promterm";
    promterm.inputs = {
      nixpkgs.follows = "nixpkgs";
      naersk.follows = "naersk";
    };

    go-karma-bot.url = "github:pinpox/go-karma-bot";
    go-karma-bot.inputs.nixpkgs.follows = "nixpkgs";

    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    wallpaper-generator.url = "github:pinpox/wallpaper-generator";
    wallpaper-generator.flake = false;

    restic-exporter.url = "github:pinpox/restic-exporter";
    restic-exporter.inputs.nixpkgs.follows = "nixpkgs";

    alertmanager-ntfy = {
      url = "github:pinpox/alertmanager-ntfy";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    matrix-hook.url = "github:pinpox/matrix-hook";
    matrix-hook.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
    };

    # ZSH plugins
    zsh-abbrev-alias.url = "github:momo-lab/zsh-abbrev-alias";
    zsh-abbrev-alias.flake = false;

    zsh-colored-man-pages.url = "github:ael-code/zsh-colored-man-pages";
    zsh-colored-man-pages.flake = false;

    nix-apple-fonts = {
      url = "github:pinpox/nix-apple-fonts";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs =
    { self, ... }@inputs:
    with inputs;
    let

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );

      clan = clan-core.lib.clan {

        # this needs to point at the repository root
        inherit self;

        # Make inputs and the flake itself accessible as module parameters.
        # Technically, adding the inputs is redundant as they can be also
        # accessed with flake-self.inputs.X, but adding them individually
        # allows to only pass what is needed to each module.
        specialArgs = {
          flake-self = self;
        }
        // inputs;

        # Register custom clan service modules
        modules."@pinpox/wireguard" = ./clan-service-modules/wireguard.nix;
        modules."@pinpox/localsend" = ./clan-service-modules/localsend.nix;
        modules."@pinpox/machine-type" = ./clan-service-modules/machine-type;

        inventory = {

          machines = {
            kiwi.tags = [ "desktop" ];
            tanne.tags = [ "desktop" ];
            kartoffel.tags = [ "destkop" ];
            limette.tags = [ "destkop" ];

            birne.tags = [ "server" ];
            kfbox.tags = [ "server" ];
            porree.tags = [ "server" ];
          };

          meta.name = "pinpox-clan";

          instances = {

            localsend = {
              module.input = "self";
              module.name = "@pinpox/localsend";
              roles.default.tags.all = { };
            };

            machine-type = {
              module.input = "self";
              module.name = "@pinpox/machine-type";
              roles.desktop.tags.desktop = { };
              roles.server.tags.server = { };
            };

            importer = {
              module.name = "importer";
              roles.default.tags.all = { };
              # Import all modules from ./modules/<module-name> on all machines
              roles.default.extraModules = (map (m: ./modules + "/${m}") (builtins.attrNames self.nixosModules));
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
                kiwi = { };
                limette = { };
              };
            };
          };
        };
      };
    in
    {

      devShells = forAllSystems (
        system: with nixpkgsFor.${system}; {
          default = pkgs.mkShell {
            packages = [
              clan-core.packages.${system}.clan-cli
            ];
          };
        }
      );

      # Custom packages {added via the overlay are selectively exposed here, to
      # allow using them from other flakes that import this one.
      packages = forAllSystems (
        system: with nixpkgsFor.${system}; {

          inherit
            hello-custom
            fritzbox_exporter
            mqtt2prometheus
            smartmon-script
            # woodpecker-pipeline
            manual
            ;
        }
      );

      # Expose overlay to flake outputs, to allow using it from other flakes.
      # Flake inputs are passed to the overlay so that the packages defined in
      # it can use the sources pinned in flake.lock
      overlays.default = final: prev: (import ./overlays inputs self pinpox-utils) final prev;

      # Use nixpkgs-fmt for 'nix fmt'
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      # Output all modules in ./modules/<module-name> to flake. Modules should be in
      # individual subdirectories and contain a default.nix file.
      # Each subdirectory in ./modules/<module-name> is a nixos module
      nixosModules = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = import (./modules + "/${name}");
        }) (builtins.attrNames (builtins.readDir ./modules))
      );

      # Each subdirectory in ./machines/<machine-name> is a host config. Clan
      # auto-imports all machines from ./machines
      inherit (clan.config) clanInternals nixosConfigurations;
      clan = clan.config;

      # Each subdirectory in ./home-manager/profiles/<profile-name> is a
      # home-manager profile
      homeConfigurations = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value =
              { ... }:
              {
                imports = [
                  (./home-manager/profiles + "/${name}")
                ]
                ++ (builtins.attrValues self.homeManagerModules);
              };
          })
          (
            builtins.attrNames (
              nixpkgs.lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./home-manager/profiles)
            )
          )
      );

      # Each subdirectory in ./home-manager/modules/<module-name> is a
      # home-manager module
      homeManagerModules = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = import (./home-manager/modules + "/${name}");
        }) (builtins.attrNames (builtins.readDir ./home-manager/modules))
      );
    };
}
