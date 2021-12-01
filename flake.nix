{
  description = "My machines";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    matrix-hook.url = "github:pinpox/matrix-hook";
    matrix-hook.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly.inputs.flake-utils.follows = "flake-utils";

    # Krops
    krops.url = "git+https://cgit.krebsco.de/krops";
    krops.flake = false;

    # Vim plugins
    indent-blankline-nvim-lua.url =
      "github:lukas-reineke/indent-blankline.nvim";
    indent-blankline-nvim-lua.flake = false;

    nvim-fzf.url = "github:vijaymarupudi/nvim-fzf";
    nvim-fzf.flake = false;

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

    nix-apple-fonts.url = "github:pinpox/nix-apple-fonts";

    nix-apple-fonts.inputs.flake-compat.follows = "flake-compat";
    nix-apple-fonts.inputs.flake-utils.follows = "flake-utils";
    nix-apple-fonts.inputs.nixpkgs.follows = "nixpkgs";

  };
  outputs = { self, ... }@inputs:
    with inputs;
    let
      # Function to create default (common) system config options
      defFlakeSystem = baseCfg:
        nixpkgs.lib.nixosSystem {

          system = "x86_64-linux";
          modules = [

            # Make inputs and overlay accessible as module parameters
            { _module.args.inputs = inputs; }
            { _module.args.self-overlay = self.overlay; }

            ({ ... }: {
              imports = builtins.attrValues self.nixosModules ++ [
                {
                  # Set the $NIX_PATH entry for nixpkgs. This is necessary in
                  # this setup with flakes, otherwise commands like `nix-shell
                  # -p pkgs.htop` will keep using an old version of nixpkgs.
                  # With this entry in $NIX_PATH it is possible (and
                  # recommended) to remove the `nixos` channel for both users
                  # and root e.g. `nix-channel --remove nixos`. `nix-channel
                  # --list` should be empty for all users afterwards
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                  nixpkgs.overlays =
                    [ self.overlay nur.overlay neovim-nightly.overlay ];

                  # DON'T set useGlobalPackages! It's not necessary in newer
                  # home-manager versions and does not work with configs using
                  # nixpkgs.config`
                  home-manager.useUserPackages = true;
                }
                baseCfg
                home-manager.nixosModules.home-manager
              ];

              # Let 'nixos-version --json' know the Git revision of this flake.
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.registry.pinpox.flake = self;
            })
          ];
        };

    in {

      # Expose overlay to flake outputs, to allow using it from other flakes.
      # Flake inputs are passed to the overlay so that the packages defined in
      # it can use the sources pinned in flake.lock
      overlay = final: prev: (import ./overlays inputs) final prev;

      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file
      nixosModules = builtins.listToAttrs (map (x: {
        name = x;
        value = import (./modules + "/${x}");
      }) (builtins.attrNames (builtins.readDir ./modules)));

      # Each subdirectory in ./machines is a host. Add them all to
      # nixosConfiguratons. Host configurations need a file called
      # configuration.nix that will be read first
      nixosConfigurations = builtins.listToAttrs (map (x: {
        name = x;
        value = defFlakeSystem {
          imports = [
            (import (./machines + "/${x}/configuration.nix") { inherit self; })
          ];
        };
      }) (builtins.attrNames (builtins.readDir ./machines)));

      /* # Hydra build jobs. Builds all configs in the CI to verify integrity
         hydraJobs = (nixpkgs.lib.mapAttrs' (name: config:
         nixpkgs.lib.nameValuePair "nixos-${name}"
         config.config.system.build.toplevel) self.nixosConfigurations);
            # // (nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair
            # "home-manager-${name}" config.activation-script)
            # self.hmConfigurations);
      */

      # nix build '.#base-image'
      base-image = let system = "x86_64-linux";
      in import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
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
      let pkgs = nixpkgs.legacyPackages.${system}.extend self.overlay;
      in rec {
        # Custom packages added via the overlay are selectively added here, to
        # allow using them from other flakes that import this one.
        packages = flake-utils.lib.flattenTree {
          wezterm-bin = pkgs.wezterm-bin;
          wezterm-nightly = pkgs.wezterm-nightly;
          hello-custom = pkgs.hello-custom;
          filebrowser = pkgs.filebrowser;
          darktile = pkgs.darktile;
          xscreensaver = pkgs.xscreensaver;
          smartmon-script = pkgs.smartmon-script;

          # rules = pkgs.writeText "secret-rules" ''
          #     ${self.nixosConfigurations.kartoffel.config.networking.hostName}
          #   '';
        };

        apps = {
          # Allow custom packages to be run using `nix run`
          hello-custom = flake-utils.lib.mkApp { drv = packages.hello-custom; };
          wezterm-bin = flake-utils.lib.mkApp {
            drv = packages.wezterm-bin;
            exePath = "/bin/wezterm";
          };
        };

        # Checks to run with `nix flake check -L`, will run in a QEMU VM.
        # Looks for all ./modules/<module name>/test.nix files and adds them to
        # the flake's checks output. The test.nix file is optional and may be
        # added to any module.
        checks = builtins.listToAttrs (map (x: {
          name = x;
          value = (import (./modules + "/${x}/test.nix")) {
            pkgs = nixpkgs;
            inherit system self;
          };
        }) (
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
