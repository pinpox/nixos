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

  options.pinpox.colors = builtins.listToAttrs (map
    (c: {
      name = c;
      value = mkOption { type = types.str; };
    })
    colornames);

  config.pinpox.colors = {

    # catppucchin macchiato

    White = "cad3f5"; #cad3f5
    BrightWhite = "a5adcb"; #a5adcb
    Black = "24273a"; #24273a
    BrightBlack = "5b6078"; #5b6078
    # BrightBlack = "#494d64";   # Surface 1
    # BrightWhite = "#b8c0e0";   # Subtext 1

    Red = "ed8796"; #ed8796"
    BrightRed = "ed8796"; #ed8796"
    Green = "a6da95"; #a6da95"
    BrightGreen = "a6da95"; #a6da95"
    Yellow = "eed49f"; #eed49f"
    BrightYellow = "fab387"; #fab387
    Blue = "8aadf4"; #8aadf4"
    BrightBlue = "74c7ec"; #74c7ec
    Magenta = "cba6f7"; #cba6f7"
    BrightMagenta = "f5bde6"; #f5bde6"
    Cyan = "8bd5ca"; #8bd5ca"
    BrightCyan = "8bd5ca"; #8bd5ca"

    /*
      # pinpox-contrast
      Black = "000000"; #000000
      BrightBlack = "2c2d3a"; #2c2d3a
      White = "fefbe6"; #fefbe6
      BrightWhite = "ECEFF4"; #ECEFF4
      Yellow = "ff9900"; #ff9900
      BrightYellow = "e1dc3f"; #e1dc3f
      Green = "3ec840"; #3ec840
      BrightGreen = "68f288"; #68f288
      Cyan = "00ecd8"; #00ecd8
      BrightCyan = "A1E4FF"; #A1E4FF
      Blue = "418fdd"; #418fdd
      BrightBlue = "5B77B3"; #5B77B3
      Magenta = "ff00cc"; #ff00cc
      BrightMagenta = "D8B3F0"; #D8B3F0
      Red = "e92741"; #e92741
      BrightRed = "FF5370"; #FF5370
    */

  };
}
