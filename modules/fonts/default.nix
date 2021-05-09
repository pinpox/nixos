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
        source-sans-pro
        source-serif-pro
        noto-fonts-emoji
        corefonts
        recursive
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "Recursive Sans Casual Static Medium" ];
          sansSerif = [ "Recursive Sans Linear Static Medium" ];
          monospace = [ "Recursive Mono Linear Static" ];
          emoji = [ "Noto Color Emoji" ];
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
