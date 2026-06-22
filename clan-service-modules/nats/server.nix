{
  instanceName,
  settings,
  roles,
  machine,
  clanLib,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = settings;
  auth = import ./auth.nix { inherit lib clanLib; };

  userGen = userName: "nats-${instanceName}-user-${userName}";

  authUsers = auth.mkAuthorizationUsers {
    flake = config.clan.core.settings.directory;
    inherit instanceName;
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

  # Per-user NKEYs (share=true — same seed on every machine the user logs
  # into). Pubkeys are committed under vars/shared/.
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
    }) (lib.attrNames cfg.users)
  );

  networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [
    cfg.clientPort
  ];

  services.nats = {
    enable = true;
    serverName = cfg.host;
    port = cfg.clientPort;
    jetstream = cfg.jetStream.enable;
    dataDir = cfg.jetStream.storeDir;
    settings = lib.mkMerge [
      {
        # Monitoring HTTP bound to loopback only — /varz, /jsz, etc. are
        # unauthenticated, so they must never be exposed off-box. Scrape
        # locally on the server or via an SSH tunnel.
        http = "127.0.0.1:${toString cfg.monitoringPort}";
        authorization.users = authUsers;
      }
      cfg.extraSettings
    ];
  };
}
