{
  pkgs,
  ...
}:
{
  imports = [ ../common.nix ];

  config = {

    # Install these packages for my user
    home.packages = with pkgs; [
      exa
      htop
      httpie
      pkg-config
      tealdeer
      unzip
    ];

    pinpox = {
      defaults = {
        credentials.enable = true;
        git.enable = true;
        shell.enable = true;
        xdg.enable = true;
      };

      programs = {
        tmux.enable = true;
      };
    };
  };
}
