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
  version = "20210818-nightly";

  src = fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = "9a112e82ac4079c3b344bb473d806f029fa58c79";
    sha256 = "sha256-8cMOcCgxdTV5RIfnOPoBRKoXy8SYK4reTorENepjJbU=";
    fetchSubmodules = true;
  };

  postPatch = ''
    echo ${version} > .tag
  '';

  cargoSha256 = "sha256-OFAz63tlURKCkf3IzAQiYFUZ7AFOl3k6+tDBV8jjXT4=";

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
