{
  description = "My machines";

  inputs = {

    wrappers.url = "github:lassulus/wrappers";
    wrappers.inputs.nixpkgs.follows = "nixpkgs";

    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable?shallow=1";
    nixpkgs.url = "github:nixos/nixpkgs/e4bae1bd10c9c57b2cf517953ab70060a828ee6f?shallow=1";
    # nixpkgs-master.url = "github:nixos/nixpkgs/master?shallow=1";

    # nixpkgs-local.url = "path:/home/pinpox/code/github.com/NixOS/nixpkgs";
    # nixpkgs-local.flake = false;

    clan-core.url = "git+https://git.clan.lol/clan/clan-core";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";

    dns-mesher.url = "git+https://git.clan.lol/pinpox/data-smasher";
    dns-mesher.inputs.nixpkgs.follows = "nixpkgs";
    dns-mesher.inputs.clan-core.follows = "clan-core";

    # caddy-patched.url = "github:pinpox/nixos-caddy-patched";
    # caddy-patched.inputs.nixpkgs.follows = "nixpkgs";

    rio.url = "github:pinpox/rio";
    rio.inputs.nixpkgs.follows = "nixpkgs";
    rio.inputs.systems.follows = "clan-core/systems";

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

    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.url = "path:/home/pinpox/code/github.com/NixOS/nixos-hardware";

    aoe-taunt-discord-bot.url = "github:pinpox/aoe-taunt-discord-bot";
    aoe-taunt-discord-bot.inputs.nixpkgs.follows = "nixpkgs";

    pinpox-keys.url = "https://github.com/pinpox.keys";
    pinpox-keys.flake = false;

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
      utils.follows = "age-plugin-picohsm/flake-utils";
    };

    go-karma-bot.url = "github:pinpox/go-karma-bot";
    go-karma-bot.inputs.nixpkgs.follows = "nixpkgs";

    rogue-talk.url = "github:rogue-talk/rogue-talk";
    rogue-talk.inputs.nixpkgs.follows = "nixpkgs";
    rogue-talk.inputs.treefmt-nix.follows = "treefmt-nix";

    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";
    retiolum.inputs.nixpkgs.follows = "nixpkgs";
    retiolum.inputs.nix-darwin.follows = "clan-core/nix-darwin";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:pinpox/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    nur.inputs.flake-parts.follows = "clan-core/flake-parts";

    wallpaper-generator.url = "github:pinpox/wallpaper-generator";
    wallpaper-generator.flake = false;

    restic-exporter.url = "github:pinpox/restic-exporter";
    restic-exporter.inputs.nixpkgs.follows = "nixpkgs";
    restic-exporter.inputs.flake-utils.follows = "age-plugin-picohsm/flake-utils";

    alertmanager-ntfy = {
      url = "github:pinpox/alertmanager-ntfy";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "age-plugin-picohsm/flake-utils";
      };
    };

    matrix-hook.url = "github:pinpox/matrix-hook";
    matrix-hook.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
      flake-utils.follows = "age-plugin-picohsm/flake-utils";
    };

    # ZSH plugins
    zsh-abbrev-alias.url = "github:momo-lab/zsh-abbrev-alias";
    zsh-abbrev-alias.flake = false;

    zsh-colored-man-pages.url = "github:ael-code/zsh-colored-man-pages";
    zsh-colored-man-pages.flake = false;

    jj-zsh-prompt.url = "github:pinpox/jj-zsh-prompt";
    jj-zsh-prompt.inputs.nixpkgs.follows = "nixpkgs";

    zsh-async.url = "github:mafredri/zsh-async";
    zsh-async.flake = false;

    nix-apple-fonts = {
      url = "github:pinpox/nix-apple-fonts";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "age-plugin-picohsm/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.follows = "clan-core/treefmt-nix";

    age-plugin-picohsm.url = "github:pinpox/age-plugin-picohsm";
    age-plugin-picohsm.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.inputs.treefmt-nix.follows = "treefmt-nix";

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

      # treefmt configuration
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgsFor.${system} {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            nixfmt.package = nixpkgsFor.${system}.nixfmt;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
          settings.formatter = {
            prettier.includes = [
              "*.md"
              "*.yaml"
              "*.yml"
              "*.json"
              "*.toml"
            ];
            shellcheck.includes = [ "*.sh" ];
            shfmt.includes = [ "*.sh" ];
          };
        }
      );

      clan = clan-core.lib.clan {

        # this needs to point at the repository root
        inherit self;

        # Vars backend configuration (moved from machine-level)
        vars.settings.secretStore = "password-store";

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
        modules."@pinpox/navidrome" = ./clan-service-modules/navidrome.nix;
        modules."@pinpox/machine-type" = ./clan-service-modules/machine-type;
        modules."@pinpox/desktop" = ./clan-service-modules/desktop;
        modules."@pinpox/dns-mesher" = dns-mesher.clan.modules.dns-mesher;

        # Include dns-mesher's custom exports module for endpoints

        inventory = import ./inventory.nix { inherit self; };
      };
    in
    {

      devShells = forAllSystems (
        system: with nixpkgsFor.${system}; {
          default = pkgs.mkShell {
            packages = [
              clan-core.packages.${system}.clan-cli
              treefmtEval.${system}.config.build.wrapper
            ];
          };
        }
      );

      # Custom packages added via the overlay are selectively exposed here, to
      # allow using them from other flakes that import this one.
      packages =
        forAllSystems (
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
        )
        // {
          # Flashable SD card image for uconsole (uses binfmt emulation)
          # Build with: nix build .#uconsole-image
          # Then flash with: dd if=result/main.raw of=/dev/sdX bs=4M status=progress

          # Build the image on the remote server
          # ssh root@build01.clan.lol \
          #   'nix build github:pinpox/nixos#packages.aarch64-linux.uconsole-image -L'

          # Download image (compressed)
          # ssh root@build01.clan.lol \
          #  'zstd -c \
          #  $(nix build github:pinpox/nixos#packages.aarch64-linux.uconsole-image --print-out-paths)/main.raw' > \
          #  uconsole.img.zst

          # Decompress
          # zstd -d uconsole.img.zst

          aarch64-linux = (forAllSystems (s: { })).aarch64-linux // {
            uconsole-image = self.nixosConfigurations.uconsole.config.system.build.diskoImages;
          };
        };

      # Expose overlay to flake outputs, to allow using it from other flakes.
      # Flake inputs are passed to the overlay so that the packages defined in
      # it can use the sources pinned in flake.lock
      overlays.default = final: prev: (import ./overlays inputs self pinpox-utils) final prev;

      # Use treefmt for 'nix fmt'
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Expose treefmt check for CI
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      # Each subdirectory in ./templates/<template-name> is a
      # template, which can be used for new proects with:
      # `nix flake init`
      templates = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {
            path = ./templates + "/${name}";
            description = (import (./templates + "/${name}/flake.nix")).description;
          };
        }) (builtins.attrNames (builtins.readDir ./templates))
      );

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
      inherit (clan.config) clanInternals;
      nixosConfigurations = clan.config.nixosConfigurations // {
        # Cross-compilation target for uconsole (build on x86_64)
        uconsole-cross = clan.config.nixosConfigurations.uconsole.extendModules {
          modules = [
            {
              nixpkgs.hostPlatform = nixpkgs.lib.mkForce "aarch64-linux";
              nixpkgs.buildPlatform = "x86_64-linux";
              boot.binfmt.emulatedSystems = nixpkgs.lib.mkForce [ ];
            }
          ];
        };
      };
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
