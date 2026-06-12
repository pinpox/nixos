{ buildGoModule, lib }:
buildGoModule {
  pname = "nats-auth-callout";
  version = "0.1.0";

  # Only the Go sources; exclude the Nix file so it doesn't perturb the hash.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./main.go
    ];
  };

  vendorHash = "sha256-RrrZXT9ND3/sNdQFV/V6qHzOZ3b3q3h7Jk8eYzz12qE=";

  meta = {
    description = "NATS auth-callout service: authenticate clients/leafs via an OIDC token (e.g. Gitea) and mint scoped user JWTs";
    mainProgram = "nats-auth-callout";
  };
}
