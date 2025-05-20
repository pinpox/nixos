{ ... }:
{
  programs.starship = {
    enable = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {

      character = {
        success_symbol = "[»](bold green)";
        error_symbol = "[×](bold red) ";
      };

      aws = {
        disabled = true;
      };

      python = {
        disabled = true;
      };

      nix_shell = {
        symbol = "❄  ";
      };

      git_status = {

        ahead = "↑";
        behind = "↓";
        diverged = "↕";
        modified = "!";
        staged = "±";
        renamed = "→";
      };

      directory = {
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 2;

        substitutions = {
          "~/code/github.com/pinpox/nixos" = "<pinpox/nixos>";
        };
      };
    };
  };
}
