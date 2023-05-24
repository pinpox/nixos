{ lib, config, ... }:
with lib;
let
  cfg = config.pinpox.programs.swaylock;
in
{
  options.pinpox.programs.swaylock.enable = mkEnableOption "swaylock screenlocker";

  config = mkIf cfg.enable {

    programs.swaylock = {
      enable = true;
      settings = {

        #  Turn the screen into the given color instead of white.
        color = "${config.pinpox.colors.Black}";
        # Sets the indicator to show even if idle.
        indicator-idle-visible = false;
        # Sets the indicator radius.
        indicator-radius = 100;
        # Sets the color of the line between the inside and ring.
        line-color = "${config.pinpox.colors.White}";
        # Show current count of failed authentication attempts.
        show-failed-attempts = true;
        # Sets the color of the ring of the indicator.
        ring-color = "${config.pinpox.colors.Green}";
        # Sets the color of the text.
        text-color = "${config.pinpox.colors.White}";
        # Sets the font of the text.
        font = "Berkeley Mono";
        # Sets a fixed font size for the indicator text.
        font-size = 24;
        # Sets the color of the inside of the indicator when invalid.
        inside-wrong-color = "${config.pinpox.colors.Red}";
        # When an empty password is provided, do not validate it.
        ignore-empty-password = true;
        # Sets the color of backspace highlight segments.
        bs-hl-color = "${config.pinpox.colors.Magenta}";
        # Sets the color of the layout text.
        layout-text-color = "${config.pinpox.colors.White}";
      };
    };
  };
}
#  -i, --image [[<output>]:]<path>  Display the given image, optionally only on the given output.
#  -k, --show-keyboard-layout       Display the current xkb layout while typing.
#  -K, --hide-keyboard-layout       Hide the current xkb layout while typing.
#  -L, --disable-caps-lock-text     Disable the Caps Lock text.
#  -l, --indicator-caps-lock        Show the current Caps Lock state also on the indicator.
#  -s, --scaling <mode>             Image scaling mode: stretch, fill, fit, center, tile, solid_color.
#  -t, --tiling                     Same as --scaling=tile.
#  -u, --no-unlock-indicator        Disable the unlock indicator.
#  --indicator-thickness <thick>    Sets the indicator thickness.
#  --indicator-x-position <x>       Sets the horizontal position of the indicator.
#  --indicator-y-position <y>       Sets the vertical position of the indicator.
#  --caps-lock-bs-hl-color <color>  Sets the color of backspace highlight segments when Caps Lock is active.
#  --caps-lock-key-hl-color <color> Sets the color of the key press highlight segments when Caps Lock is active.
#  --inside-color <color>           Sets the color of the inside of the indicator.
#  --inside-clear-color <color>     Sets the color of the inside of the indicator when cleared.
#  --inside-caps-lock-color <color> Sets the color of the inside of the indicator when Caps Lock is active.
#  --inside-ver-color <color>       Sets the color of the inside of the indicator when verifying.
#  --key-hl-color <color>           Sets the color of the key press highlight segments.
#  --layout-bg-color <color>        Sets the background color of the box containing the layout text.
#  --layout-border-color <color>    Sets the color of the border of the box containing the layout text.
#  --ring-clear-color <color>       Sets the color of the ring of the indicator when cleared.
#  --ring-caps-lock-color <color>   Sets the color of the ring of the indicator when Caps Lock is active.
#  --ring-ver-color <color>         Sets the color of the ring of the indicator when verifying.
#  --ring-wrong-color <color>       Sets the color of the ring of the indicator when invalid.
#  --separator-color <color>        Sets the color of the lines that separate highlight segments.
#  --text-clear-color <color>       Sets the color of the text when cleared.
#  --text-caps-lock-color <color>   Sets the color of the text when Caps Lock is active.
#  --text-ver-color <color>         Sets the color of the text when verifying.
#  --text-wrong-color <color>       Sets the color of the text when invalid.
