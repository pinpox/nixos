{
  description = "My machines";

  inputs = {

    # inovex-mdm = {
    #   type = "gitlab";
    #   host = "gitlab.inovex.de";
    #   owner = "ffranzmann";
    #   ref = "master";
    #   repo = "mdm-linux-inventory-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.mdm-linux-inventory.follows = "mdm-linux-inventory";
    # };
    #
    # mdm-linux-inventory = {
    #   type = "gitlab";
    #   host = "gitlab.inovex.de";
    #   owner = "inovex-it-mdm";
    #   ref = "main";
    #   repo = "mdm-linux-inventory";
    #   flake = false;
    # };

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    caddy-patched = {
      url = "github:pinpox/nixos-caddy-patched";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    aoe-taunt-discord-bot = {
      url = "github:pinpox/aoe-taunt-discord-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pinpox-keys = {
      url = "https://github.com/pinpox.keys";
      flake = false;
    };

    pinpox-neovim = {
      url = "github:pinpox/pinpox-neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    radio = {
      url = "github:pinpox/radio";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mc3000 = {
      url = "github:pinpox/mc3000";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lollypops = {
      url = "github:pinpox/lollypops";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk.url = "github:nix-community/naersk/master";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    promterm.url = "github:pinpox/promterm";
    promterm.inputs = {
      nixpkgs.follows = "nixpkgs";
      naersk.follows = "naersk";
    };

    go-karma-bot.url = "github:pinpox/go-karma-bot";
    go-karma-bot.inputs = {
      nixpkgs.follows = "nixpkgs";
    };

    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    wallpaper-generator.url = "github:pinpox/wallpaper-generator";
    wallpaper-generator.flake = false;

    restic-exporter.url = "github:pinpox/restic-exporter";
    restic-exporter.inputs = {
      nixpkgs.follows = "nixpkgs";
    };

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

    # Krops
    krops.url = "git+https://cgit.krebsco.de/krops";
    krops.flake = false;

    # Vim plugins
    indent-blankline-nvim-lua.url = "github:lukas-reineke/indent-blankline.nvim";
    indent-blankline-nvim-lua.flake = false;

    nvim-fzf.url = "github:vijaymarupudi/nvim-fzf";
    nvim-fzf.flake = false;

    nvim-cokeline.url = "github:noib3/nvim-cokeline";
    nvim-cokeline.flake = false;

    # ZSH plugins
    zsh-abbrev-alias.url = "github:momo-lab/zsh-abbrev-alias";
    zsh-abbrev-alias.flake = false;

    zsh-colored-man-pages.url = "github:ael-code/zsh-colored-man-pages";
    zsh-colored-man-pages.flake = false;

    forgit.url = "github:wfxr/forgit";
    forgit.flake = false;

    tfenv.url = "github:tfutils/tfenv";
    tfenv.flake = false;

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

    in
    {

      apps = forAllSystems (system: {
        # For testing:
        # nix flake update --override-input lollypops ../lollypops
        default = lollypops.apps."${system}".default { configFlake = self; };
      });

      # Custom packages added via the overlay are selectively exposed here, to
      # allow using them from other flakes that import this one.
      packages = forAllSystems (
        system: with nixpkgsFor.${system}; {

          inherit
            hello-custom
            filebrowser
            fritzbox_exporter
            mqtt2prometheus
            smartmon-script
            woodpecker-pipeline
            manual
            tfenv
            ;
        }
      );

      # Expose overlay to flake outputs, to allow using it from other flakes.
      # Flake inputs are passed to the overlay so that the packages defined in
      # it can use the sources pinned in flake.lock
      overlays.default = final: prev: (import ./overlays inputs self) final prev;

      # Use nixpkgs-fmt for 'nix fmt'
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file

      # Each subdirectory in ./modules/<module-name> is a nixos module
      nixosModules = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = import (./modules + "/${name}");
        }) (builtins.attrNames (builtins.readDir ./modules))
      );

      # Each subdirectory in ./machines/<machine-name> is a host config
      nixosConfigurations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = nixpkgs.lib.nixosSystem {

            # Make inputs and the flake itself accessible as module parameters.
            # Technically, adding the inputs is redundant as they can be also
            # accessed with flake-self.inputs.X, but adding them individually
            # allows to only pass what is needed to each module.
            specialArgs = {
              flake-self = self;
            } // inputs;

            system = "x86_64-linux";

            modules = [
              (./machines + "/${name}/configuration.nix")
              { imports = builtins.attrValues self.nixosModules; }
            ];
          };
        }) (builtins.attrNames (builtins.readDir ./machines))
      );

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
                  lollypops.hmModule
                ] ++ (builtins.attrValues self.homeManagerModules);
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
