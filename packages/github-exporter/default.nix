{ lib, fetchFromGitHub, buildGoModule, pkgs, inputs }:

buildGoModule rec {
  pname = "github-exporter";
  version = "latest";

  # vendorSha256 = null;
  vendorSha256 = "sha256-emTiyrU3qAmsZizdqoR81ypE6P8b6gG3orEZZ2eFaD0=";

  nativeBuildInputs = with pkgs; [ pkg-config ];

  src = inputs.github-exporter;

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.mit;
    homepage = "https://github.com/infinityworks/github-exporte";
    description = "github exporter for prometheus";
  };
}
