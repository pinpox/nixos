{ config, pkgs, lib, ... }:
with lib;
let

  cfg = config.pinpox.defaults.gtk;

  # TODO use flake inputs
  materia-theme = pkgs.fetchFromGitHub {
    owner = "nana-4";
    repo = "materia-theme";
    rev = "76cac96ca7fe45dc9e5b9822b0fbb5f4cad47984";
    sha256 = "sha256-0eCAfm/MWXv6BbCl2vbVbvgv8DiUH09TAUhoKq7Ow0k=";
    # Old version
    # "e329aaee160c82e85fe91a6467c666c7f9f2a7df";
    # sha256 = "1qmq5ycfpzv0rcp5aav4amlglkqy02477i4bdi7lgpbn0agvms6c";
    fetchSubmodules = true;
  };
  materia_colors = pkgs.writeTextFile {
    name = "gtk-generated-colors";
    text = ''
      BTN_BG=${config.pinpox.colors.BrightBlack}
      BTN_FG=${config.pinpox.colors.BrightWhite}

      FG=${config.pinpox.colors.White}
      BG=${config.pinpox.colors.Black}

      HDR_BTN_BG=${config.pinpox.colors.BrightBlack}
      HDR_BTN_FG=${config.pinpox.colors.White}

      ACCENT_BG=${config.pinpox.colors.Green}
      ACCENT_FG=${config.pinpox.colors.Black}

      HDR_FG=${config.pinpox.colors.White}
      HDR_BG=${config.pinpox.colors.BrightBlack}

      MATERIA_SURFACE=${config.pinpox.colors.BrightBlack}
      MATERIA_VIEW=${config.pinpox.colors.BrightBlack}

      MENU_BG=${config.pinpox.colors.BrightBlack}
      MENU_FG=${config.pinpox.colors.BrightWhite}

      SEL_BG=${config.pinpox.colors.Blue}
      SEL_FG=${config.pinpox.colors.Magenta}

      TXT_BG=${config.pinpox.colors.BrightBlack}
      TXT_FG=${config.pinpox.colors.BrightWhite}

      WM_BORDER_FOCUS=${config.pinpox.colors.White}
      WM_BORDER_UNFOCUS=${config.pinpox.colors.BrightBlack}

      UNITY_DEFAULT_LAUNCHER_STYLE=False
      NAME=generated
      MATERIA_COLOR_VARIANT=dark
      MATERIA_STYLE_COMPACT=True
    '';
  };
in

{
  options.pinpox.defaults.gtk.enable = mkEnableOption "gtk defaults";

  config = mkIf cfg.enable {

    nixpkgs.overlays = [
      (self: super: {
        rendersvg = self.runCommand "rendersvg" { } ''
          mkdir -p $out/bin
          ln -s ${self.resvg}/bin/resvg $out/bin/rendersvg
        '';
        generated-gtk-theme = self.stdenv.mkDerivation {

          name = "generated-gtk-theme";
          src = materia-theme;
          buildInputs = with self; [
            sassc
            bc
            which
            rendersvg
            meson
            ninja
            nodePackages.sass
            gtk4.dev
            optipng
          ];
          MATERIA_COLORS = materia_colors;
          phases = [ "unpackPhase" "installPhase" ];
          installPhase = ''
            HOME=/build
            chmod 777 -R .
            patchShebangs .
            mkdir -p $out/share/themes
            mkdir bin
            sed -e 's/handle-horz-.*//' -e 's/handle-vert-.*//' -i ./src/gtk-2.0/assets.txt
            echo "Changing colours:"
            ./change_color.sh -o Generated "$MATERIA_COLORS" -i False -t "$out/share/themes"
            chmod 555 -R .
          '';
        };
      })
    ];

    # GTK settings
    gtk = {
      enable = true;

      font = {
        name = "Berkeley Mono";
        # package = pkgs.iosevka;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      theme = {
        name = "Generated";
        package = pkgs.generated-gtk-theme;
      };

      gtk3 = {

        extraConfig = {
          gtk-cursor-theme-name = "breeze";
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };

    home.sessionVariables.GTK_THEME = "Generated";
  };
}
