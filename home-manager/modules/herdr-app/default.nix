{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.herdr-app;
  c = mapAttrs (_: v: "#${v}") config.pinpox.colors;

  # Same terminal mapping as the noctalia palette. herdr derives its panel
  # colors from these.
  ansi = [
    c.Black
    c.Red
    c.Green
    c.Yellow
    c.Blue
    c.Magenta
    c.Cyan
    c.White
    c.BrightBlack
    c.BrightRed
    c.BrightGreen
    c.BrightYellow
    c.BrightBlue
    c.BrightMagenta
    c.BrightCyan
    c.BrightWhite
  ];
  themes = {
    pinpox-dark = {
      inherit ansi;
      background = c.Black;
      foreground = c.White;
      cursor = c.White;
      selection = c.Blue;
    };
    pinpox-light = {
      inherit ansi;
      background = c.BrightWhite;
      foreground = c.Black;
      cursor = c.Black;
      selection = c.Blue;
    };
  };
in
{
  options.pinpox.programs.herdr-app.enable = mkEnableOption "herdr-app themes from pinpox.colors";

  config = mkIf cfg.enable {
    # Picked up live; choose them under Settings > Theme.
    xdg.configFile = mapAttrs' (
      name: theme: nameValuePair "herdr-app/themes/${name}.json" { text = builtins.toJSON theme; }
    ) themes;
  };
}
