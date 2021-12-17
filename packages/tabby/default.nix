{ stdenv, lib, fetchurl, dpkg, gnome2, gtk2, atk, glib, pango, gdk-pixbuf, cairo
, freetype, fontconfig, dbus, libXi, libXcursor, libXdamage, libXrandr
, libXcomposite, libXext, libXfixes, libXrender, libX11, libXtst, libXScrnSaver
, libxcb, makeWrapper, nodejs,
libxshmfence
,
libdrm
,

libxkbcommon
,
gtk3-x11
,

mesa
,
at-spi2-core,
at-spi2-atk
, nss, nspr, alsa-lib, cups, expat, systemd, libpulseaudio }:

let
  libPath = lib.makeLibraryPath [
    stdenv.cc.cc gtk2 atk glib pango gdk-pixbuf cairo freetype fontconfig dbus
    libXi libXcursor libXdamage libXrandr libXcomposite libXext libXfixes libxcb

at-spi2-core
libxkbcommon
libxshmfence
libdrm
mesa
gtk3-x11
at-spi2-atk
    libXrender libX11 libXtst libXScrnSaver gnome2.GConf nss nspr alsa-lib cups expat systemd libpulseaudio
  ];
in
stdenv.mkDerivation rec {
  version = "1.0.0-alpha.42";
  pname = "terminus";
  src = fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v1.0.168/tabby-1.0.168-linux.deb";
    sha256 = "sha256-P0o2jewxrQ1P1dK0N3G/X9DxLwkt3UMBTKpfsIObHC0=";
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ dpkg ];
  unpackPhase = ''
    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg
  '';
  installPhase = ''
    mkdir -p "$out/bin"
    mv opt "$out/"
    ln -s "$out/opt/Tabby/tabby" "$out/bin/tabby"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" --set-rpath "${libPath}:\$ORIGIN" "$out/opt/Tabby/tabby"
    mv usr/* "$out/"
    wrapProgram $out/bin/tabby --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  '';
  dontPatchELF = true;
  meta = with lib; {
    description = "A terminal for a more modern age";
    homepage    = "https://eugeny.github.io/terminus/";
    maintainers = with maintainers; [ jlesquembre ];
    license     = licenses.mit;
    platforms   = [ "x86_64-linux" ];
  };
}
