{
  stdenvNoCC,
  lib,
  inputs,
}:

# The output is the addon's module directory itself (Init.py/InitGui.py at the
# root), as `freecad.customize { modules = [ ... ]; }` expects. The addon only
# reads from here; its settings, logs and user skills live under FreeCAD's
# user config dir.
stdenvNoCC.mkDerivation {
  pname = "freecad-ai";
  version = "latest";

  src = inputs.freecad-ai;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -r . $out
  '';

  meta = with lib; {
    description = "AI assistant workbench for FreeCAD, also exposing its tools as an MCP server";
    homepage = "https://github.com/ghbalf/freecad-ai";
    license = licenses.lgpl21Only;
    platforms = platforms.unix;
  };
}
