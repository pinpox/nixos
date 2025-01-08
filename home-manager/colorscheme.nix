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

    # Default neovim colorschmeme
    # Dark:
    # blue    = "#005078"
    # cyan    = "#007676"
    # green   = "#015825"
    # grey1   = "#0a0b10"
    # grey2   = "#1c1d23"
    # grey3   = "#2c2e33"
    # grey4   = "#4f5258"
    # magenta = "#4c0049"
    # red     = "#5e0009"
    # yellow  = "#6e5600"

    # Light:
    # blue    = "#9fd8ff"
    # cyan    = "#83efef"
    # green   = "#aaedb7"
    # grey1   = "#ebeef5"
    # grey2   = "#d7dae1"
    # grey3   = "#c4c6cd"
    # grey4   = "#9b9ea4"
    # magenta = "#ffc3fa"
    # red     = "#ffbcb5"
    # yellow  = "#f4d88c"

    # foreground = e0e2ea
    # background = 14161b

    Black = "14161b";
    BrightBlack = "2c2e33";
    # BrightBlack = "4f5258";
    White = "e0e2ea";
    BrightWhite = "9b9ea4";

    BrightRed = "5e0009";
    Red = "ffbcb5";
    BrightGreen = "015825";
    Green = "aaedb7";
    BrightYellow = "6e5600";
    Yellow = "f4d88c";
    BrightBlue = "005078";
    Blue = "9fd8ff";
    BrightMagenta = "4c0049";
    Magenta = "ffc3fa";
    BrightCyan = "007676";
    Cyan = "83efef";
  };
}
