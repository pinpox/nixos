{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.fonts;
in {

  options.pinpox.defaults.fonts = { enable = mkEnableOption "Fonts defaults"; };

  config = mkIf cfg.enable {

    # Install some fonts system-wide, especially "Source Code Pro" in the
    # Nerd-Fonts pached version with extra glyphs.

    fonts = {
      fontDir.enable = true;
      fonts = with pkgs; [
        (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
        source-sans-pro
        source-serif-pro
        noto-fonts-emoji
        corefonts
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "Source Serif Pro" ];
          sansSerif = [ "Source Sans Pro" ];
          monospace = [ "SauceCodePro Nerd Font Mono" ];
        };
      };
    };
  };
}
