{ stdenv, rustPlatform, lib, fetchFromGitHub, pkg-config, fontconfig, python3
, openssl, perl, dbus, libX11, xcbutil, libxcb, xcbutilimage, xcbutilkeysyms
, xcbutilwm # contains xcb-ewmh among others
, libxkbcommon, libglvnd # libEGL.so.1
, egl-wayland, wayland, libGLU, libGL, freetype, zlib }:
let
  runtimeDeps = [
    zlib
    fontconfig
    freetype
    libX11
    xcbutil
    libxcb
    xcbutilimage
    xcbutilkeysyms
    xcbutilwm
    libxkbcommon
    dbus
    libglvnd
    egl-wayland
    wayland
    libGLU
    libGL
    openssl
  ];

in rustPlatform.buildRustPackage rec {
  pname = "wezterm-nightly";
  version = "20210502-nightly";

  src = fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = "a8f7359322f94833b49441f1c9118484abc332ba";
    sha256 = "sha256-ZEgzRrCFQNIbXMl4Radci5vceKMvhuYZBrAgwOhA5PY=";
    fetchSubmodules = true;
  };

  postPatch = ''
    echo ${version} > .tag
  '';

  cargoSha256 = "sha256-moZN4Ngo8+JQ4P4IgZKEVQ4T98SRTiDHuwNc8oWT2vM=";

  nativeBuildInputs = [ pkg-config python3 perl ];

  buildInputs = runtimeDeps;

  preFixup = lib.optionalString stdenv.isLinux ''
    for artifact in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
      patchelf --set-rpath "${
        lib.makeLibraryPath runtimeDeps
      }" $out/bin/$artifact
    done
  '';

  # prevent further changes to the RPATH
  dontPatchELF = true;

  meta = with lib; {
    description =
      "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    maintainers = with maintainers; [ steveej SuperSandro2000 ];
    platforms = platforms.unix;
  };
}
