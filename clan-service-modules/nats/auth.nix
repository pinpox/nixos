{ lib, clanLib }:
# Shared helpers for the @pinpox/nats hybrid NKEY auth model.
#
# Two principals coexist on the same NATS server:
#   - machine principal: per-host NKEY, share=false, narrow ACL
#       (publishes only its own `personal.<host>.>` + `nats.<host>.>`)
#   - user principal: per-user NKEY, share=true, broad ACL
#       (publishes anywhere a human is authorized on this clan)
#
# Both are just `{ nkey = "..."; permissions = ...; }` rows in
# `services.nats.settings.authorization.users`. NATS doesn't distinguish;
# the split is purely how the seed is generated and where it lives.
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

  defaultMachinePermissions = name: {
    publish.allow = [
      "personal.${name}.>"
      "nats.${name}.>"
    ];
    subscribe.allow = [ ">" ];
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

  # Build the full `authorization.users` list given the instance state.
  # `machines` is the union of `roles.server.machines` and
  # `roles.leaf.machines` (same shape both sides). `users` is the
  # instance-wide attrset of human principals.
  mkAuthorizationUsers =
    {
      flake,
      instanceName,
      machines,
      users,
    }:
    let
      machineEntries = lib.mapAttrsToList (name: m: {
        nkey = readPub {
          inherit flake;
          machine = name;
          generator = "nats-${instanceName}-machine";
        };
        permissions =
          if (m.settings.permissions or null) != null then
            m.settings.permissions
          else
            defaultMachinePermissions name;
      }) machines;

      userEntries = lib.mapAttrsToList (userName: userCfg: {
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
    machineEntries ++ userEntries;
in
{
  inherit
    permissionsBlock
    defaultMachinePermissions
    defaultUserPermissions
    mkAuthorizationUsers
    ;
}
