# fooyin plus extra plugins: `fooyin-with-plugins.override { plugins = [ foonic ]; }`.
#
# fooyin only searches for plugins relative to its own executable
# and in ~/.local/lib/fooyin/plugins. A symlinkJoin is not enough because the
# symlinked binary resolves back to fooyin's store path, so the unwrapped
# executable is copied and re-wrapped here. Its RUNPATH is $ORIGIN-relative,
# so fooyin's libraries are linked alongside the plugins.
{
  stdenv,
  lib,
  fooyin,
  kdePackages,
  plugins ? [ ],
}:
stdenv.mkDerivation {
  pname = "fooyin-with-plugins";
  inherit (fooyin) version;

  dontUnpack = true;

  nativeBuildInputs = [ kdePackages.wrapQtAppsHook ];

  buildInputs = [
    kdePackages.qtbase
    kdePackages.qtsvg
    kdePackages.qtwayland
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${fooyin}/bin/.fooyin-wrapped $out/bin/fooyin
    ln -s ${fooyin}/share $out/share

    mkdir -p $out/lib/fooyin/plugins
    ln -s ${fooyin}/lib/fooyin/*.so* $out/lib/fooyin/
    for dir in ${lib.concatMapStringsSep " " (p: "${p}/lib/fooyin/plugins") ([ fooyin ] ++ plugins)}; do
      ln -s "$dir"/* $out/lib/fooyin/plugins/
    done

    runHook postInstall
  '';

  qtWrapperArgs = [ "--prefix XDG_DATA_DIRS : ${fooyin}/share" ];

  meta = fooyin.meta // {
    description = "fooyin with additional plugins";
  };
}
