{ lib, fetchFromGitHub, buildGoModule, icu }:

buildGoModule rec {
  pname = "zk";
  version = "0.7.0";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-m7QGv8Vx776TsN7QHXtO+yl3U1D573UMZVyg1B4UeIk=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "mickael-menu";
    repo = "zk";
    rev = "v${version}";
    sha256 = "sha256-C3/V4v8lH4F3S51egEw5d51AI0n5xzBQjwhrI64FEGA=";
  };

  buildInputs = [ icu ];

  CGO_ENABLED = 1;

  preBuild = ''buildFlagsArray+=("-tags" "fts5 icu")'';

  # trace: warning: Use the `ldflags` and/or `tags` attributes instead of `buildFlags`/`buildFlagsArray`
  ldflags = [ "-X=main.Build=${version}" "-X=main.Build=${version}" ];

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
