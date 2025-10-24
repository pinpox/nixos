{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  inputs,
}:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-async";
  version = "latest";

  src = inputs.zsh-async;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    plugindir="$out/share/zsh-async"
    mkdir -p "$plugindir"
    cp -r * "$plugindir"/
  '';

  meta = with lib; {
    description = "Because your terminal should be able to perform tasks asynchronously without external tools!";
    homepage = "https://github.com/mafredri/zsh-async";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
