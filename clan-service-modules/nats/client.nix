{
  instanceName,
  roles,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  userGen = userName: "nats-${instanceName}-user-${userName}";

  serverMachines = roles.server.machines or { };
  # One upstream server is expected. Read its endpoint + user list from the
  # supported per-machine finalSettings path (role-level `.settings` access
  # is deprecated in clan-core).
  server = if serverMachines == { } then null else lib.head (lib.attrValues serverMachines);
  serverUrl =
    if server == null then
      ""
    else
      "nats://${server.settings.host}:${toString server.settings.clientPort}";
  users = if server == null then { } else server.settings.users;

  natsShellEnv =
    let
      arms = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          userName: _:
          "    ${userName}) export NATS_NKEY=${
                config.clan.core.vars.generators.${userGen userName}.files.seed.path
              } ;;"
        ) users
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

  # Per-user env so the `nats` CLI reaches the server with the right
  # identity: NATS_URL points upstream, NATS_NKEY at the logged-in user's
  # seed. Set for login shells (/etc/profile) and interactive shells.
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

  # Per-user NKEY seeds (share=true → the SAME seed as on the server, so a
  # user's identity is identical everywhere they log in). No nats-server
  # runs here; this machine is a pure client.
  clan.core.vars.generators = lib.mkMerge (
    map (userName: {
      ${userGen userName} = {
        share = true;
        files.seed = {
          secret = true;
          mode = "0400";
          owner = userName;
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
      };
    }) (lib.attrNames users)
  );
}
