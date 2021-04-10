{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {

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
        frame_color = "#${vars.colors.base03}";
        font = "${vars.font.normal.family} ${vars.font.normal.style} 8";
        line_height = 0;
        markup = "full";
        format =
          "<b><span foreground='#${vars.colors.base0D}'>%s</span></b>\\n<span>%b</span>";
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
        background = "#${vars.colors.base01}";
        foreground = "#${vars.colors.base03}";
        timeout = 5;
      };

      urgency_normal = {
        background = "#${vars.colors.base01}";
        foreground = "#${vars.colors.base05}";
        timeout = 10;
      };

      urgency_critical = {
        background = "#${vars.colors.base08}";
        foreground = "#${vars.colors.base00}";
        timeout = 15;
      };
    };
  };
}
