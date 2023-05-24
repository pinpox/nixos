{ lib, ... }:
with lib;
let
  colornames = [
    "Black"
    "BrightBlack"
    "White"
    "BrightWhite"
    "Yellow"
    "BrightYellow"
    "Green"
    "BrightGreen"
    "Cyan"
    "BrightCyan"
    "Blue"
    "BrightBlue"
    "Magenta"
    "BrightMagenta"
    "Red"
    "BrightRed"
  ];
in
{

  options.pinpox = {
    colors = builtins.listToAttrs (map
      (c: {
        name = c;
        value = mkOption { type = types.str; };
      })
      colornames);
  };

  config.pinpox.colors = {

    # Black = "000000"; #000000
    # BrightBlack = "2c2d3a"; #2c2d3a
    # White = "fefbe6"; #fefbe6
    # BrightWhite = "ECEFF4"; #ECEFF4
    # Yellow = "ff9900"; #ff9900
    # BrightYellow = "e1dc3f"; #e1dc3f
    # Green = "3ec840"; #3ec840
    # BrightGreen = "68f288"; #68f288
    # Cyan = "00ecd8"; #00ecd8
    # BrightCyan = "A1E4FF"; #A1E4FF
    # Blue = "418fdd"; #418fdd
    # BrightBlue = "5B77B3"; #5B77B3
    # Magenta = "ff00cc"; #ff00cc
    # BrightMagenta = "D8B3F0"; #D8B3F0
    # Red = "e92741"; #e92741
    # BrightRed = "FF5370"; #FF5370

    # Cyber23 - https://github.com/nerdbude/Cyber23
    Black = "080808";
    Red = "ff005f";
    Green = "afd75f";
    Yellow = "ffff5f";
    Blue = "0087ff";
    Magenta = "d700ff";
    Cyan = "5fd7d7";
    White = "dadada";
    BrightBlack = "1c1c1c";
    BrightRed = "ff0087";
    BrightGreen = "afd787";
    BrightYellow = "ffff87";
    BrightBlue = "00afff";
    BrightMagenta = "d75fd7";
    BrightCyan = "5fffd7";
    BrightWhite = "e4e4e4";

  };
}
