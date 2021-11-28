{ stdenv, smartmontools, python3, ... }:
stdenv.mkDerivation {
  name = "smartmon-script";
  buildInputs = [ python3 smartmontools ];
  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp ${./smartmon.py} $out/bin/smartmon-script
    chmod +x $out/bin/smartmon-script
  '';
}
