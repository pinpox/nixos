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
      export NATS_URL=nats://127.0.0.1:${toString cfg.clientPort}
      case "$USER" in
      ${arms}
      esac
    '';

in
{
  environment.systemPackages = [ pkgs.natscli ];

  # Per-user env so `nats pub`/`nats sub`/etc work directly with the right
  # identity. Set in both /etc/profile (login shells, e.g. SSH) and
  # /etc/bashrc / /etc/zshrc (interactive shells started from a GUI).
  environment.shellInit = natsShellEnv;
  environment.interactiveShellInit = natsShellEnv;

  # Per-machine NKEY (machine principal, share=false) + per-user NKEYs
  # (user principals, share=true). Pubkeys are committed to the flake
  # under vars/per-machine/ and vars/shared/ for cross-machine reads.
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

  networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [
    cfg.clientPort
    cfg.leafPort
    cfg.monitoringPort
  ];

  services.nats = {
    enable = true;
    serverName = cfg.host;
    port = cfg.clientPort;
    jetstream = cfg.jetStream.enable;
    dataDir = cfg.jetStream.storeDir;
    settings = lib.recursiveUpdate {
      http = "0.0.0.0:${toString cfg.monitoringPort}";
      leafnodes.port = cfg.leafPort;
      authorization.users = authUsers;
    } cfg.extraSettings;
  };
}
