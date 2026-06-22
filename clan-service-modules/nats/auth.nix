{ lib, clanLib }:
# Shared helpers for the @pinpox/nats per-user NKEY auth model.
#
# Each principal is one per-user NKEY (share=true — the same seed on
# every machine that user logs into), with a broad-by-default ACL. A
# "user" is a human or a dedicated application identity; create a key
# per user when integrating something that needs to talk to NATS.
#
# Each is just a `{ nkey = "..."; permissions = ...; }` row in
# `services.nats.settings.authorization.users`.
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

  defaultUserPermissions = userName: {
    publish.allow = [
      "personal.>"
      "team.${userName}.>"
      "project.>"
      "home.>"
    ];
    subscribe.allow = [ ">" ];
  };

  # Strip the trailing newline that `builtins.readFile` leaves on
  # clan-vars-generated public files. NATS tolerates whitespace in nkeys
  # but rendered JSON is cleaner without it.
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

  # Build the `authorization.users` list from the instance's user
  # principals (humans and dedicated app identities); one NKEY row each.
  mkAuthorizationUsers =
    {
      flake,
      instanceName,
      users,
    }:
    lib.mapAttrsToList (userName: userCfg: {
      nkey = readPub {
        inherit flake;
        generator = "nats-${instanceName}-user-${userName}";
      };
      permissions =
        if (userCfg.permissions or null) != null then
          userCfg.permissions
        else
          defaultUserPermissions userName;
    }) users;
in
{
  inherit
    permissionsBlock
    defaultUserPermissions
    mkAuthorizationUsers
    ;
}
