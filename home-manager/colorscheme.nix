{ lib, ... }:
with lib;
{

  options.pinpox = {
    colors = {
      # enable = mkEnableOption "foot terminal emulator";

      Black = mkOption {
        type = types.str;
        default = "000000";
      };

      # White = "FDF7CD"; # #FDF7CD
      # DarkGreen = "55D1B4"; # #55D1B4
      # DarkMagenta = "8B66A4"; # #8B66A4
      # DarkCyan = "6EB1CC"; # #6EB1CC

      BrightBlack = mkOption {
        type = types.str;
        default = "2c2d3a"; #2c2d3a
      };
      White = mkOption {
        type = types.str;
        default = "fefbe6"; #fefbe6
      };
      BrightWhite = mkOption {
        type = types.str;
        default = "ECEFF4"; #ECEFF4
      };
      Yellow = mkOption {
        type = types.str;
        default = "ff9900"; #ff9900
      };
      BrightYellow = mkOption {
        type = types.str;
        default = "e1dc3f"; #e1dc3f
      };
      Green = mkOption {
        type = types.str;
        default = "3ec840"; #3ec840
      };
      BrightGreen = mkOption {
        type = types.str;
        default = "68f288"; #68f288
      };
      Cyan = mkOption {
        type = types.str;
        default = "00ecd8"; #00ecd8
      };
      BrightCyan = mkOption {
        type = types.str;
        default = "A1E4FF"; #A1E4FF
      };
      Blue = mkOption {
        type = types.str;
        default = "418fdd"; #418fdd
      };
      BrightBlue = mkOption {
        type = types.str;
        default = "5B77B3"; #5B77B3
      };
      Magenta = mkOption {
        type = types.str;
        default = "ff00cc"; #ff00cc
      };
      BrightMagenta = mkOption {
        type = types.str;
        default = "D8B3F0"; #D8B3F0
      };
      Red = mkOption {
        type = types.str;
        default = "e92741"; #e92741
      };
      BrightRed = mkOption {
        type = types.str;
        default = "FF5370"; #FF5370
      };
    };
  };

  config = { };
}
