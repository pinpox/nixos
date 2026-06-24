{
  instanceName,
  settings,
  roles,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
# Client role: installs the `nats` CLI, points `NATS_URL` at the server, and
# deploys the HUMAN login identities (`settings.loginUsers`) — each an NKEY
# whose seed is owned by the matching Unix login, so the CLI works in that
# user's shell. App/machine identities are NOT handled here; they live in the
# nats-integrations roles that use them.
let
  keyGen = name: "nats-key-${name}";
  loginUsers = settings.loginUsers;

  serverMachines = roles.server.machines or { };
  server = if serverMachines == { } then null else lib.head (lib.attrValues serverMachines);
  serverUrl =
    if server == null then
      ""
    else
      "nats://${server.settings.host}:${toString server.settings.clientPort}";

  natsShellEnv =
    let
      arms = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: _:
          "    ${name}) export NATS_NKEY=${
            config.clan.core.vars.generators.${keyGen name}.files.seed.path
          } ;;"
        ) loginUsers
      );
    in
    ''
      export NATS_URL=${serverUrl}
      case "$USER" in
      ${arms}
      esac
    '';
in
{
  environment.systemPackages = [ pkgs.natscli ];

  # Per-user env so `nats pub`/`nats sub` work directly with the right
  # identity. Set for login shells (/etc/profile) and interactive shells.
  environment.shellInit = natsShellEnv;
  environment.interactiveShellInit = natsShellEnv;

  assertions = [
    {
      assertion = serverMachines != { };
      message = ''
        @pinpox/nats client role: no server in this instance. Assign a
        machine to `roles.server` in the same instance.
      '';
    }
  ];

  # Human login keys: NKEY seed owned by the matching login, deployed on every
  # client (share=true ⇒ same identity wherever the user logs in). Authorize
  # them in `roles.server.settings.authorizations` (keyGenerator nats-key-<name>).
  clan.core.vars.generators = lib.mkMerge (
    lib.mapAttrsToList (name: _: {
      ${keyGen name} = import ./nkey.nix {
        inherit pkgs;
        owner = name;
      };
    }) loginUsers
  );
}
