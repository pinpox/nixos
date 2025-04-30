{
  lib,
  pkgs,
  nur,
  flake-self,
  config,
  ...
}:
with lib;
{
  imports = [ ../colorscheme.nix ];

  config = {


    # Home-manager nixpkgs config
    nixpkgs = {

      # Allow "unfree" licenced packages
      config = {
        allowUnfree = true;
      };

      overlays = [
        flake-self.overlays.default
        nur.overlays.default
      ];
    };

    # Extra arguments to pass to modules
    _module.args = {
      pinpox-utils = import ../../utils { inherit pkgs; };
    };

    # Include man-pages
    manual.manpages.enable = true;

    # Environment variables
    systemd.user.sessionVariables = {
      ZDOTDIR = "/home/pinpox/.config/zsh";
    };

    home = {
      # Install these packages for my user
      packages = with pkgs; [
        eza
        htop
        pkg-config
        tealdeer
        unzip
        delta
      ];

      sessionVariables = {
        # Workaround for alacritty (might break other apps!)
        # LIBGL_ALWAYS_SOFTWARE = "1";
        ZDOTDIR = "/home/pinpox/.config/zsh";
      };

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      stateVersion = "20.09";
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
