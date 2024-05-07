{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  inputs,
}:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-colored-man-pages";
  version = "latest";

  src = inputs.zsh-colored-man-pages;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    plugindir="$out/share/zsh-colored-man-pages"
    mkdir -p "$plugindir"
    cp -r * "$plugindir"/
  '';

  meta = with lib; {
    description = "ZSH plugin that colorifies man page";
    homepage = "https://github.com/ael-code/zsh-colored-man-pages";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
