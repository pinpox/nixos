{
  config,
  pkgs,
  ...
}:
{
  config = {
    home.pointerCursor = {
      name = "Banana";
      size = 32;
      package = pkgs.banana-cursor;
      x11.enable = true;
      gtk.enable = true;
    };

    wayland.windowManager.sway.seat."*".xcursor_theme =
      "${config.gtk.cursorTheme.name} ${toString config.gtk.cursorTheme.size}";

    gtk.cursorTheme = {
      name = "Banana";
      size = 32;
      package = pkgs.banana-cursor;
    };
  };
}
