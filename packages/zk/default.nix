{ lib, fetchFromGitHub, buildGoModule, icu }:

buildGoModule rec {
  pname = "zk";
  version = "0.5.0";

  # TODO is it possibe to pin the hash in flake.lock?
  # vendorSha256 = null;
  # This should be doable with https://github.com/tweag/gomod2nix
  # vendorSha256 = "sha256-pke51qXK03h7eIk8MWIHBknmGrd+bUq8V3ZzkNnpP8c=";
vendorSha256 = "sha256-wP3ltbblyzA5bISvTqwnLkoupUCcfgQCRz6IdoFgjLc=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "mickael-menu";
    repo = "zk";
    rev = "feature/list-json";
    sha256 = "sha256-WS3NzJD49qvmzp2qzAufkfGgDV2u7qUQcTxnpSGZJ3Y=";

    # rev = "v${version}";
    # sha256 = "sha256-EFVNEkBYkhArtUfULZVRPxFCVaPHamadqFxi7zV7y8g=";
  };

  buildInputs = [ icu ];

  CGO_ENABLED = 1;

  preBuild = ''buildFlagsArray+=("-tags" "fts5 icu")'';

  buildFlagsArray =
    [ "-ldflags=-X=main.Build=${version} -X=main.Build=${version}" ];

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
