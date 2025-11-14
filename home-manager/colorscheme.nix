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

    Black = "000000"; # 000000
    BrightBlack = "262626"; #262626
    White = "d0d0d0"; # d0d0d0
    BrightWhite = "ffffff"; # ffffff
    Red = "d7005f"; # d7005f
    BrightRed = "ff5f87"; # ff5f87
    Green = "00af5f"; # 00af5f
    BrightGreen = "00d75f"; # 00d75f
    Yellow = "d78700"; # d78700
    BrightYellow = "ffaf00"; # ffaf00
    Blue = "0087d7"; # 0087d7
    BrightBlue = "00afff"; # 00afff
    Magenta = "d787d7"; # d787d7
    BrightMagenta = "ff87ff"; # ff87ff
    Cyan = "00afaf"; # 00afaf
    BrightCyan = "00d7d7"; # 00d7d7
  };
}
