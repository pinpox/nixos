{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.fonts;
in
{

  options.pinpox.defaults.fonts = { enable = mkEnableOption "Fonts defaults"; };

  config = mkIf cfg.enable {

    fonts = {
      fontDir.enable = true;
      fonts = with pkgs; [

        league-of-moveable-type
        inter
        source-sans-pro
        source-serif-pro
        noto-fonts-emoji
        corefonts
        recursive
        iosevka-bin
      ];

      fontconfig = {
        defaultFonts = {
          serif =
            [ "Berkeley Mono" "Inconsolata Nerd Font Mono" ];
          sansSerif =
            [ "Berkeley Mono" "Inconsolata Nerd Font Mono" ];
          monospace =
            [ "Berkeley Mono" "Inconsolata Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
