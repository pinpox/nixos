{ config, pkgs, lib, ... }:
let
  vars = import ./vars.nix;
  materia-theme = pkgs.fetchFromGitHub {
    owner = "nana-4";
    repo = "materia-theme";
    rev = "e329aaee160c82e85fe91a6467c666c7f9f2a7df";
    sha256 = "1qmq5ycfpzv0rcp5aav4amlglkqy02477i4bdi7lgpbn0agvms6c";
    fetchSubmodules = true;
  };
  materia_colors = pkgs.writeTextFile {
    name = "gtk-generated-colors";
    text = ''
      BTN_BG=${vars.colors.base02}
      BTN_FG=${vars.colors.base06}

      FG=${vars.colors.base05}
      BG=${vars.colors.base00}

      HDR_BTN_BG=${vars.colors.base01}
      HDR_BTN_FG=${vars.colors.base05}

      ACCENT_BG=${vars.colors.base0B}
      ACCENT_FG=${vars.colors.base00}

      HDR_FG=${vars.colors.base05}
      HDR_BG=${vars.colors.base02}

      MATERIA_SURFACE=${vars.colors.base02}
      MATERIA_VIEW=${vars.colors.base01}

      MENU_BG=${vars.colors.base02}
      MENU_FG=${vars.colors.base06}

      SEL_BG=${vars.colors.base0D}
      SEL_FG=${vars.colors.base0E}

      TXT_BG=${vars.colors.base02}
      TXT_FG=${vars.colors.base06}

      WM_BORDER_FOCUS=${vars.colors.base05}
      WM_BORDER_UNFOCUS=${vars.colors.base03}

      UNITY_DEFAULT_LAUNCHER_STYLE=False
      NAME=generated
      MATERIA_COLOR_VARIANT=dark
      MATERIA_STYLE_COMPACT=True
    '';
  };
in {

  nixpkgs.overlays = [
    (self: super: {
      generated-gtk-theme = self.stdenv.mkDerivation rec {
        name = "generated-gtk-theme";
        src = materia-theme;
        buildInputs = with self; [ sassc bc which inkscape optipng ];
        installPhase = ''
          HOME=/build
          chmod 777 -R .
          patchShebangs .
          mkdir -p $out/share/themes
          substituteInPlace change_color.sh --replace "\$HOME/.themes" "$out/share/themes"
          echo "Changing colours:"
          ./change_color.sh -o Generated ${materia_colors}
          chmod 555 -R .
        '';
      };
    })
  ];

  # GTK settings
  gtk = {
    enable = true;

    font = {
      name = "Source Sans Pro";
      package = pkgs.source-sans-pro;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Generated";
      package = pkgs.generated-gtk-theme;
    };
    gtk3.extraConfig.gtk-cursor-theme-name = "breeze";
  };

  home.sessionVariables.GTK_THEME = "Generated";

}
