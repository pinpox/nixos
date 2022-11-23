{ pkgs, nur, flake-self, config, ... }:
let
  vars = import ../vars.nix;
in
{

  # lollypops-hm-test

  # Home-manager nixpkgs config
  nixpkgs = {

    # Allow "unfree" licenced packages
    config = { allowUnfree = true; };

    overlays = [
      flake-self.overlays.default
      nur.overlay
      # inputs.neovim-nightly.overlay
    ];
  };

  lollypops.secrets = {
    cmd-name-prefix = "nixos-secrets/users/pinpox/";
    default-dir = "${config.home.homeDirectory}/.lollypops-secrets";
    files."usertest" = { };
  };

  # programs.neovim.package = pkgs.neovim-nightly;

  # Extra arguments to pass to modules
  _module.args = {
    utils = import ../../utils { inherit pkgs; };
    colorscheme = vars.colors;
    fonts = vars.font;
  };

  # Include man-pages
  manual.manpages.enable = true;

  # Environment variables
  systemd.user.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    ZDOTDIR = "/home/pinpox/.config/zsh";
  };

  home = {
    # Install these packages for my user
    packages = with pkgs; [
      exa
      htop
      httpie
      pkg-config
      tealdeer
      unzip
      delta
    ];

    sessionVariables = {
      # Workaround for alacritty (breaks wezterm and other apps!)
      # LIBGL_ALWAYS_SOFTWARE = "1";
      EDITOR = "nvim";
      VISUAL = "nvim";
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
}
