{ config, pkgs, lib, ... }:
with lib;
let

  cfg = config.pinpox.programs.dunst;
in
{
  options.pinpox.programs.dunst.enable = mkEnableOption "dunst notificatinos";

  config = mkIf cfg.enable {

    services.dunst = {
      enable = true;

      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus";
        size = "22x22";
      };

      settings = {

        global = {
          monitor = 0;
          follow = "mouse";
          geometry = "300x5-50+50";
          indicate_hidden = "yes";
          shrink = "no";
          transparency = 0;
          notification_height = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          frame_width = 0;
          separator_color = "frame";
          sort = "yes";
          frame_color = "#${config.pinpox.colors.BrightBlack}";
          font = "${config.pinpox.font.normal.family} ${config.pinpox.font.normal.style} 8";
          line_height = 0;
          markup = "full";
          format =
            "<b><span foreground='#${config.pinpox.colors.Blue}'>%s</span></b>\\n<span>%b</span>";
          alignment = "left";
          show_age_threshold = 60;
          word_wrap = "yes";
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = "yes";
          hide_duplicate_count = "false";
          show_indicators = "no";
          icon_position = "left";
          max_icon_size = 32;
          sticky_history = "yes";
          history_length = 20;
          browser = "${pkgs.chromium}/bin/chromium";
          always_run_script = "true";
          title = "Dunst";
          class = "Dunst";
          startup_notification = "false";
        };

        shortcuts = {
          close = "ctrl+space";
          close_all = "ctrl+shift+space";
          history = "ctrl+grave";
          context = "ctrl+shift+period";
        };

        urgency_low = {
          background = "#${config.pinpox.colors.BrightBlack}";
          foreground = "#${config.pinpox.colors.BrightBlack}";
          timeout = 5;
        };

        urgency_normal = {
          background = "#${config.pinpox.colors.BrightBlack}";
          foreground = "#${config.pinpox.colors.White}";
          timeout = 10;
        };

        urgency_critical = {
          background = "#${config.pinpox.colors.Red}";
          foreground = "#${config.pinpox.colors.Black}";
          timeout = 15;
        };
      };
    };
  };
}
