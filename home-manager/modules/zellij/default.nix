{ lib, config, ... }:
with lib;
let
  cfg = config.pinpox.programs.zellij;
in
{
  options.pinpox.programs.zellij.enable = mkEnableOption "zellij terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.zellij = {

      enable = true;

      # Don't auto-start zellij on new shells
      enableZshIntegration = false;

      settings = {

        keybinds.unbind = "Ctrl q";

        session_serialization = false;
        show_startup_tips = false;
        simplified_ui = true;

        # 0.45.0+ enters Scroll mode on mouse scroll-up, so typing hits
        # scroll-mode bindings (e.g. `s` = search). Restore the old behaviour:
        # stay in Normal mode, typing snaps back to the bottom.
        scroll_mode_sync = false;

        theme = "custom";
        themes.custom = {
          fg = "#${config.pinpox.colors.White}";
          bg = "#${config.pinpox.colors.BrightBlack}";
          black = "#${config.pinpox.colors.Black}";
          red = "#${config.pinpox.colors.Red}";
          green = "#${config.pinpox.colors.Green}";
          yellow = "#${config.pinpox.colors.BrightYellow}";
          blue = "#${config.pinpox.colors.Blue}";
          magenta = "#${config.pinpox.colors.Magenta}";
          cyan = "#${config.pinpox.colors.Cyan}";
          white = "#${config.pinpox.colors.White}";
          orange = "#${config.pinpox.colors.Yellow}";
        };
      };
    };
  };
}
