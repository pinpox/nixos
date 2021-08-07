{ lib, fetchFromGitHub, buildGoModule, pkgs }:

buildGoModule rec {
  pname = "darktile";
  version = "0.0.9";

  vendorSha256 = null;

  buildInputs = with pkgs; [
    libglvnd.dev
    xlibs.libXext.dev
    xlibs.libXi.dev
    xorg.libX11
    xorg.libX11.dev
    xorg.libXcursor
    xorg.libXft
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXxf86vm
    xorg.xinput
  ];

  nativeBuildInputs = with pkgs; [ pkg-config ];

  src = fetchFromGitHub {
    owner = "liamg";
    repo = "darktile";
    rev = "v${version}";
    sha256 = "sha256-NMo9DC9O87U4TdnoHaNseFdF5KuZnmFpfQK22T758eo=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.mit;
    description =
      "GPU rendered terminal emulator designed for tiling window managers.";
  };
}
