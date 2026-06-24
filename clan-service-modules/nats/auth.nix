{ lib, clanLib }:
# Helpers for the @pinpox/nats authorization model. The server is a pure
# authorizer: it is handed a set of `authorizations` (each = a public-key
# generator reference + an ACL) and turns them into the nats
# `authorization.users` list by reading each generator's committed `pub`. It
# never holds seeds — those live wherever the owning role (client / an
# integration) runs.
let
  permissionsBlock = lib.types.submodule {
    options = {
      publish.allow = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subject patterns this principal is permitted to publish.";
      };
      publish.deny = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subject patterns explicitly denied (takes precedence over allow).";
      };
      subscribe.allow = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subject patterns this principal is permitted to subscribe to.";
      };
      subscribe.deny = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subject patterns explicitly denied (takes precedence over allow).";
      };
    };
  };

  # Strip the trailing newline that `builtins.readFile` leaves on
  # clan-vars-generated public files. NATS tolerates whitespace in nkeys but
  # rendered JSON is cleaner without it.
  readPub =
    {
      flake,
      machine ? null,
      generator,
    }:
    lib.removeSuffix "\n" (
      clanLib.getPublicValue {
        inherit flake machine generator;
        file = "pub";
      }
    );

  # Build the nats `authorization.users` list from a set of authorizations:
  # each entry names the clan vars generator holding its public key plus its
  # ACL. One NKEY row per entry; no seed material involved.
  mkAuthorizationUsers =
    {
      flake,
      authorizations,
    }:
    lib.mapAttrsToList (_name: a: {
      nkey = readPub {
        inherit flake;
        generator = a.keyGenerator;
      };
      inherit (a) permissions;
    }) authorizations;
in
{
  inherit
    permissionsBlock
    readPub
    mkAuthorizationUsers
    ;
}
