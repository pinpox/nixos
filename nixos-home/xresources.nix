{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
  # # Xresources
  # xresources.extraConfig = builtins.readFile (
  #   pkgs.fetchFromGitHub {
  #     owner = "solarized";
  #     repo = "xresources";
  #     rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
  #     sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
  #   } + "/Xresources.dark"
  #   );
  xresources.properties = {
    "color0" = "#${vars.colors.base00}";
    "color1" = "#${vars.colors.base01}";
    "color2" = "#${vars.colors.base02}";
    "color3" = "#${vars.colors.base03}";
    "color4" = "#${vars.colors.base04}";
    "color5" = "#${vars.colors.base05}";
    "color6" = "#${vars.colors.base06}";
    "color7" = "#${vars.colors.base07}";
    "color8" = "#${vars.colors.base08}";
    "color9" = "#${vars.colors.base09}";
    "color10" = "#${vars.colors.base0A}";
    "color11" = "#${vars.colors.base0B}";
    "color12" = "#${vars.colors.base0C}";
    "color13" = "#${vars.colors.base0D}";
    "color14" = "#${vars.colors.base0E}";
    "color15" = "#${vars.colors.base0F}";
  };
}
