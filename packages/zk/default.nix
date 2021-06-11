{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "zk";
  version = "0.5.0";

  # TODO is it possibe to pin the hash in flake.lock?
  # vendorSha256 = null;
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-pkW51qXK03h7eIk8MWIHBknmGrd+bUq8V3ZzkNnpP8c=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "mickael-menu";
    repo = "zk";
    rev = "v${version}";
    sha256 = "sha256-EFVNEkBYkhArtUfULZVRPxFCVaPHamadqFxi7zV7y8g=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
