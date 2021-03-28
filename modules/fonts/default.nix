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
        ubuntu_font_family
        pkgs.dejavu_fonts
        noto-fonts-emoji
        corefonts
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "Ubuntu" ];
          sansSerif = [ "Ubuntu" ];
          monospace = [ "Ubuntu" ];
        };
      };
    };
  };
}
