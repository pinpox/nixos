{
  pkgs,
  owner ? "root",
}:
# Shared NKEY user generator: one Ed25519 keypair. `share = true` ⇒ a single
# key cluster-wide, stored once. The secret `seed` is deployed only to the
# machines that DECLARE this generator (a login machine via the client role,
# or the one machine an integration role runs on). The `pub` is committed to
# `vars/shared/` so the server can authorize the identity without ever holding
# its seed. This is the single definition of "an NKEY identity"; the client
# role and every nats-integrations role import it.
{
  share = true;
  files.seed = {
    secret = true;
    mode = "0400";
    inherit owner;
  };
  files.pub.secret = false;
  runtimeInputs = with pkgs; [
    nkeys
    coreutils
  ];
  script = ''
    nk -gen user -pubout > pair
    head -n1 pair > $out/seed
    tail -n1 pair > $out/pub
  '';
}
