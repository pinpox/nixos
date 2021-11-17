{ lib, fetchFromGitHub, buildGoModule, pkgs }:

buildGoModule rec {
  pname = "ssh-vault";
  version = "0.12.8";

  # runVend = true;
  # vendorSha256 = null;
  vendorSha256 = "sha256-bMNiy0U78ejc9yxy8FQeSjm/n0X2ex2Qnt6O+U5mlQE=";
  doCheck = false;

  # buildInputs = with pkgs; [
  #   libglvnd.dev
  #   xlibs.libXext.dev
  #   xlibs.libXi.dev
  #   xorg.libX11
  #   xorg.libX11.dev
  #   xorg.libXcursor
  #   xorg.libXft
  #   xorg.libXinerama
  #   xorg.libXrandr
  #   xorg.libXxf86vm
  #   xorg.xinput
  # ];

  # nativeBuildInputs = with pkgs; [ pkg-config ];

  src = fetchFromGitHub {
    owner = "ssh-vault";
    repo = "ssh-vault";
    rev = "${version}";
    sha256 = "sha256-3D1ibsqXvM6SzQ2r+vOq8ZbMWBvBt/rsFHMupiLvD3Q=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.bsd3;
    description = "TODO";
  };
}

# https://github.com/ssh-vault/ssh-vault
