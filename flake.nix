{
  description = "My machines";

  inputs = {

    mayniklas-keys = {
      url = "https://github.com/MayNiklas.keys";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    lollypops = {
      url = "github:pinpox/lollypops";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };

    promterm.url = "github:pinpox/promterm";
    promterm.inputs = {
      nixpkgs.follows = "nixpkgs";
      utils.follows = "flake-utils";
    };

    s3photoalbum.url = "github:pinpox/s3photoalbum";
    s3photoalbum.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      # home-manager.follows = "home-manager";
    };

    retiolum.url = "github:krebs/retiolum";
    retiolum.flake = false;


    flake-utils.url = "github:numtide/flake-utils";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # Home-manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    wallpaper-generator.url = "github:pinpox/wallpaper-generator";
    wallpaper-generator.flake = false;
    wallpaper-generator.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles-awesome.url = "github:pinpox/dotfiles-awesome";
    dotfiles-awesome.inputs = {
      nixpkgs.follows = "nixpkgs";
      wallpaper-generator.follows = "wallpaper-generator";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };

    restic-exporter.url = "github:pinpox/restic-exporter";
    restic-exporter.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };

    matrix-hook.url = "github:pinpox/matrix-hook";
    matrix-hook.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };

    # neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    # neovim-nightly.inputs.nixpkgs.follows = "nixpkgs";
    # neovim-nightly.inputs.flake-utils.follows = "flake-utils";

    # Krops
    krops.url = "git+https://cgit.krebsco.de/krops";
    krops.flake = false;

    # Vim plugins
    indent-blankline-nvim-lua.url =
      "github:lukas-reineke/indent-blankline.nvim";
    indent-blankline-nvim-lua.flake = false;

    nvim-fzf.url = "github:vijaymarupudi/nvim-fzf";
    nvim-fzf.flake = false;

    nvim-cokeline.url = "github:noib3/nvim-cokeline";
    nvim-cokeline.flake = false;

    fzf-lua.url = "github:ibhagwan/fzf-lua";
    fzf-lua.flake = false;

    zk-nvim.url = "github:megalithic/zk.nvim";
    zk-nvim.flake = false;

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
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iosevka-custom = {
      url = "github:pinpox/iosevka-custom";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = { self, ... }@inputs:
    with inputs;
    {

      # Expose overlay to flake outputs, to allow using it from other flakes.
      # Flake inputs are passed to the overlay so that the packages defined in
      # it can use the sources pinned in flake.lock
      overlays.default = final: prev: (import ./overlays inputs) final prev;

      # Use nixpkgs-fmt for `nix fmt'
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file
      nixosModules = builtins.listToAttrs (map
        (x: {
          name = x;
          value = import (./modules + "/${x}");
        })
        (builtins.attrNames (builtins.readDir ./modules)));

      # Each subdirectory in ./machines is a host. Add them all to
      # nixosConfiguratons. Host configurations need a file called
      # configuration.nix that will be read first
      nixosConfigurations = builtins.listToAttrs (map
        (x: {
          name = x;
          value = nixpkgs.lib.nixosSystem {

            # Make inputs and the flake itself accessible as module parameters.
            # Technically, adding the inputs is redundant as they can be also
            # accessed with flake-self.inputs.X, but adding them individually
            # allows to only pass what is needed to each module.
            specialArgs = { flake-self = self; } // inputs;

            system = "x86_64-linux";

            modules = [
              (./machines + "/${x}/configuration.nix")
              { imports = builtins.attrValues self.nixosModules; }
              home-manager.nixosModules.home-manager
              restic-exporter.nixosModules.default
            ];
          };
        })
        (builtins.attrNames (builtins.readDir ./machines)));

      homeConfigurations = {

        # For servers (no gui)
        server = { pkgs, lib, username, ... }: {
          imports = [
            ./home-manager/profiles/common.nix
            ./home-manager/profiles/server.nix
          ] ++
          (builtins.attrValues self.homeManagerModules);
        };

        # For workstations (X11 + awesome)
        desktop = { pkgs, lib, username, ... }: {
          imports = [
            ./home-manager/profiles/common.nix
            ./home-manager/profiles/desktop.nix
          ] ++
          (builtins.attrValues self.homeManagerModules);
        };
      };

      homeManagerModules = builtins.listToAttrs (map
        (name: {
          inherit name;
          value = import (./home-manager/modules + "/${name}");
        })
        (builtins.attrNames (builtins.readDir ./home-manager/modules)));

      /* # Hydra build jobs. Builds all configs in the CI to verify integrity
        hydraJobs = (nixpkgs.lib.mapAttrs' (name: config:
        nixpkgs.lib.nameValuePair "nixos-${name}"
        config.config.system.build.toplevel) self.nixosConfigurations);
        # // (nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair
        # "home-manager-${name}" config.activation-script)
        # self.hmConfigurations);
      */

      # nix build '.#base-image'
      base-image =
        let system = "x86_64-linux";
        in
        import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
          pkgs = nixpkgs.legacyPackages."${system}";
          lib = nixpkgs.lib;
          config = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [ ./images/configuration.nix ];
          }).config;
          format = "qcow2";
          diskSize = 2048;
          name = "base-image";
        };

    } //

    # All packages in the ./packages subfolder are also added to the flake.
    # flake-utils is used for this part to make each package available for each
    # system. This works as all packages are compatible with all architectures
    (flake-utils.lib.eachSystem [ "aarch64-linux" "i686-linux" "x86_64-linux" ])
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}.extend self.overlays.default;
        in
        rec {
          # Custom packages added via the overlay are selectively exposed here, to
          # allow using them from other flakes that import this one.
          packages = flake-utils.lib.flattenTree {
            # wezterm-bin = pkgs.wezterm-bin;
            wezterm-nightly = pkgs.wezterm-nightly;
            hello-custom = pkgs.hello-custom;
            filebrowser = pkgs.filebrowser;
            darktile = pkgs.darktile;
            dirserver = pkgs.dirserver;
            fritzbox_exporter = pkgs.fritzbox_exporter;
            mqtt2prometheus = pkgs.mqtt2prometheus;
            xscreensaver = pkgs.xscreensaver;
            smartmon-script = pkgs.smartmon-script;
            tfenv = pkgs.tfenv;
          };

          # Run with: nix develop '.#test-shell'
          devShells = flake-utils.lib.flattenTree {
            test-shell = import ./shells/test-shell.nix { inherit pkgs; };
          };

          # Allow custom packages to be run using `nix run`
          apps =
            let
              configFlake = self;
              # {
              # nixosConfigurations = {
              #   host1 = nixpkgs.lib.nixosSystem {
              #     system = "x86_64-linux";
              #     modules = [ lollypops.nixosModules.lollypops ];
              #   };
              # };
              # };
            in
            {
              # TODO for testing
              # nix flake update --override-input lollypops ../lollypops
              default = lollypops.apps."${system}".default { inherit configFlake; };
              # hello-custom = flake-utils.lib.mkApp { drv = packages.hello-custom; };
            };

          # defaultApp = apps.hello-custom;
          # Checks to run with `nix flake check -L`, will run in a QEMU VM.
          # Looks for all ./modules/<module name>/test.nix files and adds them to
          # the flake's checks output. The test.nix file is optional and may be
          # added to any module.
          checks = builtins.listToAttrs
            (map
              (x: {
                name = x;
                value = (import (./modules + "/${x}/test.nix")) {
                  pkgs = nixpkgs;
                  inherit system self;
                };
              })
              (
                # Filter list of modules, leaving only modules which contain a
                # `test.nix` file
                builtins.filter
                  (p: builtins.pathExists (./modules + "/${p}/test.nix"))
                  (builtins.attrNames (builtins.readDir ./modules))));

          # TODO we probably should set some default app and/or package
          # defaultPackage = packages.hello;
          # defaultApp = apps.hello;
        });
}
