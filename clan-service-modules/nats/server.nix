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
  bridgeGen = "nats-${instanceName}-team-bridge";
  sysGen = "nats-${instanceName}-sys";

  hasFederation = cfg.federation != null;

  allMachines = (roles.server.machines or { }) // (roles.leaf.machines or { });

  authUsers = auth.mkAuthorizationUsers {
    flake = config.clan.core.settings.directory;
    inherit instanceName;
    machines = allMachines;
    users = cfg.users;
  };

  # Federation accounts (single leaf connection, deterministic, no cycle).
  #
  # The cycle detector is order-sensitive: one account both exporting
  # `team.pinpox.>` and importing an overlapping `team.*.>` intermittently
  # false-positives "import forms a cycle". Fix: keep LOCAL's exported and
  # imported patterns strictly DISJOINT.
  #   - LOCAL exports ONLY `exportSubjects` (e.g. team.pinpox.>) to BRIDGE.
  #   - LOCAL imports ONLY `team.peers.*.>` and `shared.>` from BRIDGE.
  #
  # BRIDGE is the single leaf-bound account. The crucial asymmetry that
  # makes this work: account `mappings` apply to messages DELIVERED OVER
  # THE LEAF, but NOT to messages imported cross-account from LOCAL.
  #   - Outbound: LOCAL's `team.pinpox.>` is imported into BRIDGE
  #     unchanged (imports skip mappings) and forwarded up the leaf as-is.
  #   - Inbound: peers' `team.*.>` arriving over the leaf IS mapped to
  #     `team.peers.<other>.>`, then exported to LOCAL (disjoint from the
  #     export, so no cycle). `shared.>` is not matched by the mapping and
  #     passes through unchanged.
  # Verified end-to-end with a local two-server (hub+leaf) reproduction.
  exps = cfg.federation.exportSubjects;
  inMappings = { "team.*.>" = "team.peers.{{wildcard(1)}}.>"; };

  federationAccounts = lib.optionalAttrs hasFederation {
    SYS.users = [
      { nkey = lib.removeSuffix "\n" config.clan.core.vars.generators.${sysGen}.files.pub.value; }
    ];
    LOCAL = {
      jetstream = true;
      users = authUsers;
      exports = map (s: {
        stream = s;
        accounts = [ "BRIDGE" ];
      }) exps;
      imports = [
        { stream = { account = "BRIDGE"; subject = "team.peers.*.>"; }; }
        { stream = { account = "BRIDGE"; subject = "shared.>"; }; }
      ];
    };
    BRIDGE = {
      imports = map (s: {
        stream = {
          account = "LOCAL";
          subject = s;
        };
      }) exps;
      mappings = inMappings;
      exports = [
        { stream = "team.peers.*.>"; accounts = [ "LOCAL" ]; }
        { stream = "shared.>"; accounts = [ "LOCAL" ]; }
      ];
    };
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

  # Federation runtime config: the leaf-remote nkey must be the seed VALUE
  # inline (nats has no seed-file option for leaf nkey, and `credentials`
  # is JWT-only). To keep the seed out of /nix/store, the rendered config
  # carries an `@TEAM_BRIDGE_SEED@` placeholder; at service start we copy
  # the config into the unit's RuntimeDirectory (tmpfs) and substitute the
  # real seed from the systemd credential before exec'ing nats-server.
  fedConfigFile = (pkgs.formats.json { }).generate "nats-fed.json" config.services.nats.settings;
  fedStart = pkgs.writeShellScript "nats-fed-start" ''
    set -eu
    umask 077
    seed=$(cat "$CREDENTIALS_DIRECTORY/team-bridge.seed")
    # Write via redirect (not sed -i / install): the unit's SystemCallFilter
    # blocks fchown, which in-place edit and `install` invoke -> SIGSYS.
    ${pkgs.gnused}/bin/sed "s|@TEAM_BRIDGE_SEED@|$seed|" ${fedConfigFile} > "$RUNTIME_DIRECTORY/nats.json"
    exec ${pkgs.nats-server}/bin/nats-server -c "$RUNTIME_DIRECTORY/nats.json"
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
    # Federation: per-machine bridge identity (seed stays on this host).
    # Pubkey goes into the team-nats's `teammates.<name>.nkey` by hand.
    ++ lib.optional hasFederation {
      ${bridgeGen} = {
        share = false;
        files.seed = {
          secret = true;
          mode = "0440";
          owner = "nats";
        };
        files.pub.secret = false;
        # NATS-decorated creds file for leaf remote `credentials = "/path"`.
        # Pure-NKEY (no JWT): nats-server's creds parser accepts a file
        # containing just the seed wrapped in the standard markers.
        files.creds = {
          secret = true;
          mode = "0440";
          owner = "nats";
        };
        runtimeInputs = with pkgs; [
          nkeys
          coreutils
        ];
        script = ''
          nk -gen user -pubout > pair
          head -n1 pair > $out/seed
          tail -n1 pair > $out/pub
          {
            printf -- '-----BEGIN USER NKEY SEED-----\n'
            cat $out/seed
            printf -- '\n------END USER NKEY SEED------\n'
          } > $out/creds
        '';
      };
    }
    # SYS account user — required when accounts are configured.
    ++ lib.optional hasFederation {
      ${sysGen} = {
        share = false;
        files.seed = {
          secret = true;
          mode = "0440";
          owner = "nats";
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
    }
  );

  # Federation: ship the raw bridge seed via systemd credential, run the
  # leaf through a wrapper that substitutes it into the runtime config
  # (see fedStart). validateConfig is off because the in-store config holds
  # the @TEAM_BRIDGE_SEED@ placeholder, which isn't a valid seed for `-t`.
  services.nats.validateConfig = lib.mkIf hasFederation false;
  systemd.services.nats.serviceConfig = lib.mkIf hasFederation {
    LoadCredential = [
      "team-bridge.seed:${config.clan.core.vars.generators.${bridgeGen}.files.seed.path}"
    ];
    RuntimeDirectory = "nats";
    ExecStart = lib.mkForce fedStart;
  };

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
    settings = lib.mkMerge [
      {
        http = "0.0.0.0:${toString cfg.monitoringPort}";
        leafnodes.port = cfg.leafPort;
      }
      # Without federation: stay in the implicit $G account with the
      # original authorization.users shape.
      (lib.mkIf (!hasFederation) {
        authorization.users = authUsers;
      })
      # With federation: accounts model + outbound leaf to the team bus.
      (lib.mkIf hasFederation {
        accounts = federationAccounts;
        system_account = "SYS";
        leafnodes.remotes = [
          (
            {
              urls = [ cfg.federation.teamUrl ];
              account = "BRIDGE";
              # Placeholder; fedStart substitutes the real seed at runtime.
              nkey = "@TEAM_BRIDGE_SEED@";
            }
            // lib.optionalAttrs (cfg.federation.tls.caFile != null) {
              tls = {
                ca_file = toString cfg.federation.tls.caFile;
                handshake_first = true;
              };
            }
          )
        ];
      })
      cfg.extraSettings
    ];
  };
}
