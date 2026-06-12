{ clanLib, lib, ... }:
# v2: hybrid NKEY auth. Per-machine machine-principals + per-user
# user-principals share one `authorization.users` registry. Server and
# leaf nats-servers both validate against the same list (each machine's
# local clients hit its own loopback nats); leaves additionally use their
# own machine creds for the outbound leafnode connection.
#
# Out of scope, planned as follow-ups when needed:
#   - federation peers across teammates (accounts block, leaf remotes,
#     allowlisted exports — see `agent://designfederation`)
#   - JetStream encryption-at-rest with a per-machine key
#   - declarative JetStream streams via a convergence oneshot
#   - companion modules for ingestion: nats-vector-journald,
#     nats-forgejo-bridge, nats-caddy-shipper, nats-desktop
let
  auth = import ./auth.nix { inherit lib clanLib; };

  # Submodule type for a human user entry under `settings.users`.
  userType = lib.types.submodule {
    options.permissions = lib.mkOption {
      type = lib.types.nullOr auth.permissionsBlock;
      default = null;
      defaultText = lib.literalExpression ''
        # publish.allow = [ "personal.>" "team.<user>.>" "project.>" "home.>" ]
        # subscribe.allow = [ ">" ]
      '';
      description = ''
        NATS subject ACL for this user's principal. `null` (default) uses
        the broad-user defaults: publish anywhere except other users'
        `team.>` namespaces, subscribe everything.
      '';
    };
  };
in
{
  _class = "clan.service";
  manifest.name = "nats";
  manifest.description = "NATS messaging system with hybrid NKEY auth (machines + users).";
  manifest.readme = ''
    Two roles plus a hybrid identity model:

      - server: full nats-server with JetStream. Listens for clients
        (4222), monitoring (8222), leaf (7422).
      - leaf:   nats-server in leaf-only mode. Loopback client listener;
        connects upstream to every machine in `roles.server.machines`.

    Every machine in either role has its own Ed25519 NKEY (machine
    principal, share=false). Every human declared in `roles.<role>.settings.users`
    has their own Ed25519 NKEY (user principal, share=true — same seed
    on every machine they log into). Both populate the same
    `authorization.users` list on every nats-server in the instance.

    Default ACLs:
      - machine M:  publish personal.M.>, nats.M.>;  subscribe >
      - user    U:  publish personal.>, team.U.>, project.>, home.>;
                    subscribe >

    Override per machine via `roles.<role>.machines.<m>.settings.permissions`,
    per user via `roles.<role>.settings.users.<u>.permissions`.

    The `clan-nats publish <subject> [...]` CLI is installed on every
    machine. It picks credentials in this order:
      1. $CLAN_NATS_CREDS (explicit override)
      2. $CREDENTIALS_DIRECTORY/nats.creds (systemd LoadCredential case)
      3. user lookup table by $USER (interactive shell case)
    Wraps `nats pub` with CloudEvents v1.0 binary-mode headers.

    Bootstrap: run `clan vars generate` once for every machine + every
    user pubkey before the first `clan machines update`. Pubkey files
    are committed under `vars/per-machine/` and `vars/shared/`.

    Upstream NixOS `services.nats` is singleton per host — one nats
    instance per machine. A machine MUST be in exactly one of `server`
    or `leaf` for a given instance.
  '';
  manifest.categories = [ "Network" ];
  manifest.exports.out = [ "endpoints" ];

  roles.server = {
    description = "NATS hub: nats-server with JetStream.";
    interface =
      { lib, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = ''
              Public hostname this server advertises. Published via
              `endpoints` for PKI cert issuance + dm-dns CNAMEs.
            '';
            example = "nats.example.com";
          };
          clientPort = lib.mkOption {
            type = lib.types.port;
            default = 4222;
            description = "Client protocol port.";
          };
          leafPort = lib.mkOption {
            type = lib.types.port;
            default = 7422;
            description = "Leaf-node accept port.";
          };
          monitoringPort = lib.mkOption {
            type = lib.types.port;
            default = 8222;
            description = "Monitoring HTTP port (/varz, /healthz).";
          };
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open client, leaf, and monitoring ports in the firewall.";
          };
          jetStream = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable JetStream on this server.";
            };
            storeDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/nats";
              description = "JetStream / nats-server data directory.";
            };
          };
          permissions = lib.mkOption {
            type = lib.types.nullOr auth.permissionsBlock;
            default = null;
            description = ''
              NATS subject ACL for this machine's machine-principal.
              `null` (default) uses the narrow per-machine defaults
              (publish only own `personal.<host>.>` + `nats.<host>.>`).
            '';
          };
          users = lib.mkOption {
            type = lib.types.attrsOf userType;
            default = { };
            description = ''
              Human users whose NKEY seeds get deployed to every machine
              they log into (share=true). Each user gets the broad-user
              default ACL unless overridden.
            '';
            example = lib.literalExpression ''{ pinpox = { }; }'';
          };
          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Free-form passthrough merged into `services.nats.settings`.";
          };
        };
      };

    perInstance =
      {
        instanceName,
        settings,
        roles,
        machine,
        mkExports,
        ...
      }:
      {
        exports = mkExports { endpoints.hosts = [ settings.host ]; };
        nixosModule = import ./server.nix {
          inherit
            instanceName
            settings
            roles
            machine
            clanLib
            ;
        };
      };
  };

  roles.leaf = {
    description = "NATS satellite: nats-server in leaf-only mode.";
    interface =
      { lib, ... }:
      {
        options = {
          remotes = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            defaultText = lib.literalExpression "derived from roles.server.machines";
            description = ''
              Explicit list of `nats-leaf://host:port` URLs. `null`
              derives the list from `roles.server.machines` in the
              same instance.
            '';
          };
          permissions = lib.mkOption {
            type = lib.types.nullOr auth.permissionsBlock;
            default = null;
            description = "NATS subject ACL for this leaf's machine-principal. `null` = defaults.";
          };
          users = lib.mkOption {
            type = lib.types.attrsOf userType;
            default = { };
            description = "Human users. Must match the server role's users (same seed shared).";
            example = lib.literalExpression ''{ pinpox = { }; }'';
          };
          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Free-form passthrough merged into `services.nats.settings`.";
          };
        };
      };

    perInstance =
      {
        instanceName,
        settings,
        roles,
        machine,
        ...
      }:
      {
        nixosModule = import ./leaf.nix {
          inherit
            instanceName
            settings
            roles
            machine
            clanLib
            ;
        };
      };
  };
}
