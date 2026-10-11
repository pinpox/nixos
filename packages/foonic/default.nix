# Subsonic browser/streaming plugin for fooyin.
# Installs lib/fooyin/plugins/fyplugin_foonic.so; load it via fooyin-with-plugins.
{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  fooyin,
  kdePackages,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "foonic";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "iljasrb";
    repo = "foonic";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XTHwNjIUiiKvKXIqHTjzX0hRTAGPjHVeUkBBd3CrJcM=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    fooyin
    kdePackages.qtbase
  ];

  # Shared object loaded by fooyin, not an application.
  dontWrapQtApps = true;

  # create_fooyin_plugin installs into FooyinConfig's absolute
  # FOOYIN_PLUGIN_INSTALL_DIR (fooyin's own store path); copy the module
  # into our output instead.
  installPhase = ''
    runHook preInstall
    install -Dm755 fyplugin_foonic.so -t $out/lib/fooyin/plugins
    runHook postInstall
  '';

  meta = {
    description = "fooyin plugin to browse and stream music from Subsonic servers";
    homepage = "https://github.com/iljasrb/foonic";
    platforms = lib.platforms.linux;
  };
})
