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

  options.pinpox.colors = builtins.listToAttrs (
    map (c: {
      name = c;
      value = mkOption { type = types.str; };
    }) colornames
  );

  config.pinpox.colors = {

    Black = "24273a"; # 24273a
    BrightBlack = "5b6078"; # 5b6078
    White = "cad3f5"; # cad3f5
    BrightWhite = "747c9e"; # 747c9e
    Red = "ed8796"; # ed8796
    BrightRed = "ff5370"; # FF5370
    Green = "a6da95"; # a6da95
    BrightGreen = "68f288"; # 68f288
    Yellow = "eed49f"; # eed49f
    BrightYellow = "fab387"; # fab387
    Blue = "8aadf4"; # 8aadf4
    BrightBlue = "74c7ec"; # 74c7ec
    Magenta = "cba6f7"; # cba6f7
    BrightMagenta = "f5bde6"; # f5bde6
    Cyan = "8bd5ca"; # 8bd5ca
    BrightCyan = "aee2da"; # aee2da
  };
}
