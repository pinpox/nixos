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
          emoji = [ "Noto Color Emoji" ];
          monospace = [ "SauceCodePro Nerd Font Mono" ];
        };

        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias binding="weak">
              <family>monospace</family>
              <prefer>
                <family>emoji</family>
              </prefer>
            </alias>
            <alias binding="weak">
              <family>sans-serif</family>
              <prefer>
                <family>emoji</family>
              </prefer>
            </alias>
            <alias binding="weak">
              <family>serif</family>
              <prefer>
                <family>emoji</family>
              </prefer>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
