{ lib, stdenv
, fetchFromGitHub
, meson
, ninja
, sassc
, gnome
, gtk-engine-murrine
, gdk-pixbuf
, librsvg
}:

stdenv.mkDerivation rec {
  pname = "materia-theme";
  version = "20200916";

  src = fetchFromGitHub {
    owner = "nana-4";
    repo = pname;
    rev = "v${version}";
    sha256 = "0qaxxafsn5zd2ysgr0jyv5j73360mfdmxyd55askswlsfphssn74";
  };

  nativeBuildInputs = [
    meson
    ninja
    sassc
  ];

  buildInputs = [
    gnome.gnome-themes-extra
    gdk-pixbuf
    librsvg
  ];

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  dontBuild = true;

  mesonFlags = [
    "-Dgnome_shell_version=${lib.versions.majorMinor gnome.gnome-shell.version}"
  ];

  postInstall = ''
    rm $out/share/themes/*/COPYING
  '';

  meta = with lib; {
    description = "Material Design theme for GNOME/GTK based desktop environments";
    homepage = "https://github.com/nana-4/materia-theme";
    license = licenses.gpl2Only;
    platforms = platforms.all;
    maintainers = [ maintainers.mounium ];
  };
}# { pkgs, stdenv, fetchFromGitHub }:
# let
#   vars = import ../../home-manager/modules/vars.nix;
#   materia-theme = pkgs.fetchFromGitHub {
#     owner = "nana-4";
#     repo = "materia-theme";
#     # rev = "e329aaee160c82e85fe91a6467c666c7f9f2a7df";
#     # sha256 = "1qmq5ycfpzv0rcp5aav4amlglkqy02477i4bdi7lgpbn0agvms6c";
#     rev = "76cac96ca7fe45dc9e5b9822b0fbb5f4cad47984";
#     sha256 = "sha256-0eCAfm/MWXv6BbCl2vbVbvgv8DiUH09TAUhoKq7Ow0k=";
#     fetchSubmodules = true;
#   };
#   materia_colors = pkgs.writeTextFile {
#     name = "gtk-generated-colors";
#     text = ''
#       BTN_BG=${vars.colors.Grey}
#       BTN_FG=${vars.colors.BrightWhite}

#       FG=${vars.colors.White}
#       BG=${vars.colors.Black}

#       HDR_BTN_BG=${vars.colors.DarkGrey}
#       HDR_BTN_FG=${vars.colors.White}

#       ACCENT_BG=${vars.colors.Green}
#       ACCENT_FG=${vars.colors.Black}

#       HDR_FG=${vars.colors.White}
#       HDR_BG=${vars.colors.Grey}

#       MATERIA_SURFACE=${vars.colors.Grey}
#       MATERIA_VIEW=${vars.colors.DarkGrey}

#       MENU_BG=${vars.colors.Grey}
#       MENU_FG=${vars.colors.BrightWhite}

#       SEL_BG=${vars.colors.Blue}
#       SEL_FG=${vars.colors.Magenta}

#       TXT_BG=${vars.colors.Grey}
#       TXT_FG=${vars.colors.BrightWhite}

#       WM_BORDER_FOCUS=${vars.colors.White}
#       WM_BORDER_UNFOCUS=${vars.colors.BrightGrey}

#       UNITY_DEFAULT_LAUNCHER_STYLE=False
#       NAME=generated
#       MATERIA_COLOR_VARIANT=dark
#       MATERIA_STYLE_COMPACT=True
#     '';
#   };

# in stdenv.mkDerivation rec {
#   name = "generated-gtk-theme";
#   # meta.homepage = "TODO";
#   src = materia-theme;
#   buildInputs = with pkgs; [ meson bc inkscape optipng sassc which ninja nodejs sass nodePackages.sass];
#   installPhase = ''
#     HOME=/build
#     chmod 777 -R .
#     patchShebangs .
#     mkdir -p $out/share/themes
#     substituteInPlace change_color.sh --replace "\$HOME/.themes" "$out/share/themes"
#     echo "Changing colours:"
#     ./change_color.sh -o Generated ${materia_colors}
#     chmod 555 -R .
#   '';
# }
