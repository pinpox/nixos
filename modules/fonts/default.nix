{ config, pkgs, lib, iosevka-custom, ... }:
with lib;
let cfg = config.pinpox.defaults.fonts;
in
{

  options.pinpox.defaults.fonts = { enable = mkEnableOption "Fonts defaults"; };

  config = mkIf cfg.enable {

    # Install some fonts system-wide, especially "Source Code Pro" in the
    # Nerd-Fonts pached version with extra glyphs.

    nixpkgs.overlays = [ iosevka-custom.overlay ];

    fonts = {
      fontDir.enable = true;
      fonts = with pkgs; [
        source-sans-pro
        source-serif-pro
        noto-fonts-emoji
        corefonts
        recursive
        # iosevka
        # (iosevka-bin.override { variant = "aile"; })
        # (iosevka-bin.override { variant = "etoile"; })
        iosevka-bin
        iosevka-fixed
        iosevka-qp
        # (iosevka.override {
        #   set = "slab-terminal";
        #   privateBuildPlan = ''
        #     [buildPlans.iosevka-slab-terminal]
        #     family = "Iosevka Slab Terminal"
        #     spacing = "term"
        #     serifs = "slab"
        #     no-cv-ss = false
        #     no-ligation = true
        #   '';
        # })


        # (iosevka.override {
        #   set = "proportional-custom";
        #   privateBuildPlan = ''
        #     [buildPlans.iosevka-proportional-custom]
        #     family = "Iosevka Proportional Custom"
        #     spacing = "quasi-proportional"
        #     serifs = "sans"
        #     no-cv-ss = true
        #       [buildPlans.iosevka-proportional-custom.variants]
        #       inherits = "ss07"
        #         [buildPlans.iosevka-proportional-custom.variants.design]
        #         f = "flat-hook-crossbar-at-x-height"
        #         n = "straight"
        #         t = "flat-hook"
        #       [buildPlans.iosevka-proportional-custom.ligations]
        #       inherits = "dlig"
        #   '';
        # })
      ];

      fontconfig = {
        defaultFonts = {
          serif =
            [ "Iosevka Semi-Bold Expanded" "Inconsolata Nerd Font Mono" ];
          sansSerif =
            [ "Iosevka Semi-Bold Expanded" "Inconsolata Nerd Font Mono" ];
          monospace =
            [ "Iosevka Semi-Bold Expanded" "Inconsolata Nerd Font Mono" ];

          # serif =
          #   [ "Recursive Sans Casual Static" "Inconsolata Nerd Font Mono" ];
          # sansSerif =
          #   [ "Recursive Sans Linear Static" "Inconsolata Nerd Font Mono" ];
          # monospace =
          #   [ "Recursive Mono Linear Static" "Inconsolata Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };

        # localConf = ''
        #   <?xml version="1.0"?>
        #   <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        #   <fontconfig>
        #     <alias binding="weak">
        #       <family>monospace</family>
        #       <prefer>
        #         <family>emoji</family>
        #       </prefer>
        #     </alias>
        #     <alias binding="weak">
        #       <family>sans-serif</family>
        #       <prefer>
        #         <family>emoji</family>
        #       </prefer>
        #     </alias>
        #     <alias binding="weak">
        #       <family>serif</family>
        #       <prefer>
        #         <family>emoji</family>
        #       </prefer>
        #     </alias>
        #   </fontconfig>
        # '';
      };
    };
  };
}
