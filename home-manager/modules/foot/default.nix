{ colorscheme, lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.programs.foot;
in
{
  options.pinpox.programs.foot.enable =
    mkEnableOption "foot terminal emulator";

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      inconsolata-nerdfont # Fallback Nerd Font to provide special glyphs
      foot
    ];

    programs.foot = {
      enable = true;
      server.enable = true;
      settings = {

        main = {
          term = "xterm-256color";

          font = "Berkeley Mono:size=11";
          # dpi-aware = "yes"; # Defaults to auto
        };

        scrollback = {
          lines = 10000;
        };

        cursor = {
          style = "beam";
          blink = "yes";
          # beam-thickness = 
        };

        colors = {

          # alpha=1.0
          background = "${colorscheme.Black}";
          foreground = "${colorscheme.White}";

          ## Normal/regular colors (color palette 0-7)
          regular0 = "${colorscheme.Black}"; # black
          regular1 = "${colorscheme.Red}"; # red
          regular2 = "${colorscheme.Green}"; # green
          regular3 = "${colorscheme.Yellow}"; # yellow
          regular4 = "${colorscheme.Blue}"; # blue
          regular5 = "${colorscheme.Magenta}"; # magenta
          regular6 = "${colorscheme.Cyan}"; # cyan
          regular7 = "${colorscheme.White}"; # white

          ## Bright colors (color palette 8-15)
          bright0 = "${colorscheme.BrightBlack}"; # black
          bright1 = "${colorscheme.BrightRed}"; # red
          bright2 = "${colorscheme.BrightGreen}"; # green
          bright3 = "${colorscheme.BrightYellow}"; # yellow
          bright4 = "${colorscheme.BrightBlue}"; # blue
          bright5 = "${colorscheme.BrightMagenta}"; # magenta
          bright6 = "${colorscheme.BrightCyan}"; # cyan
          bright7 = "${colorscheme.BrightWhite}"; # white
        };

        # mouse = {
        #   hide-when-typing = "yes";
        # };

      };
    };

  };
}
