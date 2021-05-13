{ stdenv
, rustPlatform
, lib
, fetchFromGitHub
, pkg-config
, fontconfig
, python3
, openssl
, perl
, dbus
, libX11
, xcbutil
, libxcb
, xcbutilimage
, xcbutilkeysyms
, xcbutilwm # contains xcb-ewmh among others
, libxkbcommon
, libglvnd # libEGL.so.1
, egl-wayland
, wayland
, libGLU
, libGL
, freetype
, zlib
}:
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
in

rustPlatform.buildRustPackage rec {
  pname = "wezterm-nightly";
  version = "20210502-nightly";

  src = fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = "f4e96689529168cc52f022e3867c73a9495fce75";
    sha256 = "sha256-hEkS3mjWHSJ7zCRBXe/2d1vAiUDON6RaEx+3C8/5X1o=";
    fetchSubmodules = true;
  };

  postPatch = ''
    echo ${version} > .tag
  '';

  cargoSha256 = "sha256-Tx08LQzrUcKoNX0haWTDyd6ceLwrryYVFWsmh7dHLhQ=";

  nativeBuildInputs = [
    pkg-config
    python3
    perl
  ];

  buildInputs = runtimeDeps;

  preFixup = lib.optionalString stdenv.isLinux ''
    for artifact in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
      patchelf --set-rpath "${lib.makeLibraryPath runtimeDeps}" $out/bin/$artifact
    done
  '';

  # prevent further changes to the RPATH
  dontPatchELF = true;

  meta = with lib; {
    description = "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    maintainers = with maintainers; [ steveej SuperSandro2000 ];
    platforms = platforms.unix;
  };
}