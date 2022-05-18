{ lib
, pkgs
, dotfiles-awesome
, nur
, config
, flake-self
, ...
}:
with lib; let
  cfg = config.pinpox.server;
in
{
  imports = [ ../../users/pinpox.nix ];

  options.pinpox.server = {
    enable = mkEnableOption "the default server configuration";

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
      imports = [
        ../../home-manager/home-server.nix
        dotfiles-awesome.nixosModules.dotfiles
        {
          nixpkgs.overlays = [
            flake-self.overlays.default
            nur.overlay
            # neovim-nightly.overlay
          ];
        }
      ];
    };

    # Limit log size for journal
    services.journald.extraConfig = "SystemMaxUse=1G";

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
