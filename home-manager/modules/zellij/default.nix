{ lib, config, pkgs, colorscheme, ... }:
with lib;
let cfg = config.pinpox.programs.zellij;
in
{
  options.pinpox.programs.zellij.enable =
    mkEnableOption "zellij terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;

      settings = {
        theme = "custom";
        themes.custom = {
          fg = "#${colorscheme.White}";
          bg = "#${colorscheme.Black}";
          black = "#${colorscheme.Black}";
          red = "#${colorscheme.Red}";
          green = "#${colorscheme.Green}";
          yellow = "#${colorscheme.BrightYellow}";
          blue = "#${colorscheme.Blue}";
          magenta = "#${colorscheme.Magenta}";
          cyan = "#${colorscheme.Cyan}";
          white = "#${colorscheme.White}";
          orange = "#${colorscheme.Yellow}";
        };
      };
    };
  };
}
