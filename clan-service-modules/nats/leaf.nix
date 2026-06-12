{
  instanceName,
  settings,
  roles,
  machine,
  clanLib,
}:
{ config, pkgs, lib, ... }:
let
  cfg = settings;
  auth = import ./auth.nix { inherit lib clanLib; };

  machineGen = "nats-${instanceName}-machine";
  userGen = userName: "nats-${instanceName}-user-${userName}";

  allMachines = (roles.server.machines or { }) // (roles.leaf.machines or { });
  serverMachines = roles.server.machines or { };
  derivedRemotes = lib.mapAttrsToList (
    _name: m: "nats-leaf://${m.settings.host}:${toString m.settings.leafPort}"
  ) serverMachines;
  remotes = if cfg.remotes != null then cfg.remotes else derivedRemotes;

  authUsers = auth.mkAuthorizationUsers {
    flake = config.clan.core.settings.directory;
    inherit instanceName;
    machines = allMachines;
    users = cfg.users;
  };
  natsShellEnv =
    let
      arms = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          userName: _:
          "    ${userName}) export NATS_NKEY=${
            config.clan.core.vars.generators.${userGen userName}.files.seed.path
          } ;;"
        ) cfg.users
      );
    in
    ''
      export NATS_URL=nats://127.0.0.1:4222
      case "$USER" in
      ${arms}
      esac
    '';


in
{
  environment.systemPackages = [ pkgs.natscli ];

  # Per-user env so `nats` CLI works directly with the right identity.
  environment.shellInit = natsShellEnv;
  environment.interactiveShellInit = natsShellEnv;

  assertions = [
    {
      assertion = remotes != [ ];
      message = ''
        @pinpox/nats leaf role: no remotes to connect to. Either set
        `settings.remotes` explicitly, or assign at least one machine to
        `roles.server` in the same instance.
      '';
    }
  ];

  # Per-machine NKEY for this leaf + per-user NKEYs mirrored from the
  # server (share=true). The leaf needs the user list to authenticate
  # local clients on its loopback nats; it needs its own machine creds
  # for the outbound leafnode connection.
  clan.core.vars.generators = lib.mkMerge (
    [
      {
        ${machineGen} = {
          share = false;
          files.seed = {
            secret = true;
            mode = "0440";
            owner = "nats";
          };
          files.pub.secret = false;
          # pure NKEY auth: just the seed; loaded into the unit via LoadCredential.
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
      }
    ]
    ++ map (userName: {
      ${userGen userName} = {
        share = true;
        files.seed = {
          secret = true;
          mode = "0400";
          owner = userName;
        };
        files.pub.secret = false;
          # pure NKEY auth: just the seed; --nkey takes this file directly.
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
    }) (lib.attrNames cfg.users)
  );

  # The leaf's outbound leafnode connection authenticates as this
  # machine's machine principal. nats-server reads the creds file from
  # systemd's credentials store; we add it to the upstream-managed unit.
  systemd.services.nats.serviceConfig.LoadCredential = [
    "machine.seed:${config.clan.core.vars.generators.${machineGen}.files.seed.path}"
  ];

  services.nats = {
    enable = true;
    jetstream = false;
    settings = lib.recursiveUpdate {
      host = "127.0.0.1"; # leaves only accept local clients on loopback
      authorization.users = authUsers;
      leafnodes.remotes = map (url: {
        urls = [ url ];
        nkey = "/run/credentials/nats.service/machine.seed";
      }) remotes;
    } cfg.extraSettings;
  };
}
