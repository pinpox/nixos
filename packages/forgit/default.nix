{ stdenvNoCC, lib, fetchFromGitHub, inputs }:

stdenvNoCC.mkDerivation rec {
  pname = "forgit";
  version = "latest";

  src = inputs.forgit;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    plugindir="$out/share/forgit"
    mkdir -p "$plugindir"
    cp -r * "$plugindir"/
  '';

  meta = with lib; {
    description =
      "A utility tool powered by fzf for using git interactively.";
      homepage = "https://github.com/wfxr/forgit";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
