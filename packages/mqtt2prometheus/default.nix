{ lib, fetchFromGitHub, buildGoModule, pkgs }:

# https://github.com/hikhvar/mqtt2prometheus

buildGoModule rec {
  pname = "mqtt2prometheus";
  version = "latest";

  # vendorHash = null;
  vendorHash = "sha256-5DIU1NUEVI7Fz6UHhC6trva9qd47DwdFNw1OxY6M37s=";

  nativeBuildInputs = with pkgs; [ pkg-config ];

  # Updated 2022-01-11
  src = fetchFromGitHub {
    owner = "hikhvar";
    repo = "mqtt2prometheus";
    rev = "v0.1.6";
    sha256 = "sha256-55WAuu6n2h0IPIjt8iTJzNSF1Fe7roxiIS8MUXmu5Tc=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.mit;
    description = "TODO";
  };
}
