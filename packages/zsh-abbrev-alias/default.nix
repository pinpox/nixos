{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  inputs,
}:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-abbrev-alias";
  version = "latest";

  src = inputs.zsh-abbrev-alias;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    plugindir="$out/share/zsh-abbrev-alias"
    mkdir -p "$plugindir"
    cp -r * "$plugindir"/
  '';

  meta = with lib; {
    description = "ZSH plugin with functionality similar to Vim's abbreviation expansion.";
    homepage = "https://github.com/momo-lab/zsh-abbrev-alias";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
