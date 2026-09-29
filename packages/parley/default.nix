{
  lib,
  fetchFromGitea,
  buildGoModule,
  go_1_27,
}:

# https://git.mills.io/prologic/parley
# Federated, decentralised chat that speaks plain IRC.
# go.mod requires go 1.27, newer than nixpkgs' default go.

(buildGoModule.override { go = go_1_27; }) (finalAttrs: {
  pname = "parley";
  version = "0.5.0";

  src = fetchFromGitea {
    domain = "git.mills.io";
    owner = "prologic";
    repo = "parley";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DnoVNqCuhLHeU+puICZzIEYK9Tw02daFQ9VHkSo9kpQ=";
  };

  vendorHash = "sha256-siSavE8i/Rh6LfI+HXhyKsPrbfyncJCcEYJsA4KZ378=";

  subPackages = [
    "cmd/parleyd"
    "cmd/parleyctl"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
  ];

  # Federation tests spin up real HTTP servers and tickers
  doCheck = false;

  meta = {
    description = "Federated, decentralised chat that speaks plain IRC";
    homepage = "https://git.mills.io/prologic/parley";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ pinpox ];
    mainProgram = "parleyd";
  };
})
