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
          federation = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                teamUrl = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    URL of the team-nats hub. Recommended:
                    `tls://host:7422` (native leaf protocol + TLS — the
                    NATS-blessed pattern). `wss://host/` also works if the
                    hub is behind a websocket-terminating proxy.
                  '';
                  example = "tls://nats.example.com:7422";
                };
                tls.caFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = ''
                    CA/cert (PEM) used to verify the hub's TLS certificate.
                    `null` (default) trusts the system CA store — correct
                    for publicly-trusted certs (Let's Encrypt). For a
                    self-signed hub cert, set this to the hub's `cert.pem`
                    (obtained out-of-band, same channel as the bridge
                    pubkey exchange).
                  '';
                };
                exportSubjects = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = ''
                    Local subject patterns forwarded UP to the team bus.
                    Empty list (default) means nothing crosses — useful
                    for receive-only federation. Be explicit; this is
                    half of the defense-in-depth (the other half is the
                    team-server's per-teammate `allowPublish`).
                  '';
                  example = [ "team.pinpox.>" ];
                };
                # Inbound behavior is fixed (not user-configurable) because
                # it's the load-bearing cycle-breaker: peers' `team.*.>`
                # are renamed to `team.peers.<other>.>` and `shared.>`
                # passes through. See the federation description below.
              };
            });
            default = null;
            description = ''
              Cross-clan federation to a team-nats hub. When set, the
              server gains a leaf-bound `BRIDGE` account and one outbound
              leaf connection to `teamUrl`. The bridge NKEY is generated
              automatically (`nats-<instance>-team-bridge` vars generator);
              paste the matching pubkey into the team-nats's
              `teammates.<name>.nkey`.

              Account topology (single leaf connection, deterministic — no
              import/export cycle):
                - LOCAL holds your firehose (users + JetStream). It exports
                  ONLY `exportSubjects` to BRIDGE and imports back
                  `team.peers.*.>` and `shared.>` — disjoint patterns, so
                  the cycle detector can never false-positive.
                - BRIDGE is bound to the leaf. Outbound subjects arrive
                  prefixed `out.` and a per-subject mapping strips the
                  prefix before they go up. Inbound `team.*.>` from the hub
                  is mapped to `team.peers.<other>.>` before reaching LOCAL.

              Net effect, no peer list anywhere, fully dynamic:
                - `nats sub 'team.<self>.>'`   your own events
                - `nats sub 'team.peers.>'`    every teammate's events
                - `nats sub 'shared.>'`        the shared bus

              `exportSubjects` is the leaf-side allowlist: nothing leaves
              this machine unless listed (default `[ ]` = receive-only).
              That's the user-controlled, deny-by-default share list.

              Enabling federation switches the account model: users move
              from the implicit global ($G) account into `LOCAL`, so any
              pre-existing JetStream streams need recreating.
            '';
            example = lib.literalExpression ''
              {
                teamUrl = "tls://nats.example.com:7422";
                exportSubjects = [ "team.pinpox.>" ];
                tls.caFile = ./hub-ca.pem;
              }
            '';
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
