{ buildGoModule, lib }:
buildGoModule {
  pname = "clan-nats-token";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./main.go
    ];
  };
  vendorHash = "sha256-VMWfLqo+G8r+92Ll55tEuiyLQ/c1yKnDZSIOY+46Rt8=";

  meta = {
    description = "Obtain/refresh an OIDC token (auth-code+PKCE login, refresh grant) to present to a NATS auth-callout";
    mainProgram = "clan-nats-token";
  };
}
