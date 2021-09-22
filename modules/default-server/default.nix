{ lib, pkgs, config, inputs, self-overlay, ... }:
with lib;
let cfg = config.pinpox.server;
in {

  imports = [ ../../users/pinpox.nix ];

  options.pinpox.server = {
    enable = mkEnableOption "Enable the default server configuration";

    hostname = mkOption {
      type = types.str;
      default = null;
      example = "deepblue";
      description = "hostname to identify the instance";
    };
  };

  config = mkIf cfg.enable {

    networking.hostName = cfg.hostname;

    # Server-specific home-manager config
    home-manager.users.pinpox = {

      # Pass inputs to home-manager modules
      _module.args.flake-inputs = inputs;

      imports = [
        ../../home-manager/home-server.nix
        inputs.dotfiles-awesome.nixosModules.dotfiles
        {
          nixpkgs.overlays =
            [ self-overlay inputs.nur.overlay inputs.neovim-nightly.overlay ];
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      universal-ctags
      git
      gnumake
      go
      htop
      neovim
      nix-index
      nixfmt
      python
      ripgrep
      wget
    ];

    # pinpox.metrics.node.enable = true;
    pinpox.defaults = {
      environment.enable = true;
      locale.enable = true;
      nix.enable = true;
      zsh.enable = true;
      networking.enable = true;
    };
    pinpox.services = { openssh.enable = true; };
  };
}
