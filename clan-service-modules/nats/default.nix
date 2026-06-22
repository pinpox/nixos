{ clanLib, lib, ... }:
# v3: per-user NKEY auth, two roles. Each declared user (human or
# dedicated app identity) gets one Ed25519 NKEY (share=true) listed in
# the server's `authorization.users`. The `server` role runs nats-server;
# `client` machines just get the CLI + those seeds + a remote NATS_URL.
# No per-machine keys.
#
# Out of scope, planned as follow-ups when needed:
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
  manifest.description = "NATS messaging system with per-user NKEY auth.";
  manifest.readme = ''
    Two roles, per-user NKEY identity:

      - server: a full nats-server with JetStream. The client port (4222)
        is reachable on the clan network when `openFirewall` is set;
        monitoring (8222) is bound to loopback only.
      - client: no local nats-server — just the `nats` CLI, the declared
        users' NKEY seeds, and `NATS_URL` pointing at the server.

    Identity is per-user NKEY only. Every human or application declared in
    `roles.server.settings.users` gets its own Ed25519 NKEY (share=true —
    the same seed on every machine the user logs into), listed in the
    server's `authorization.users`. Clients deploy the same seeds, so a
    user's `nats pub`/`nats sub` work identically on the server or any
    client. Add a dedicated user when integrating an application.

    Default user ACL:
      publish personal.>, team.<user>.>, project.>, home.>;  subscribe >
    Override per user via `roles.server.settings.users.<u>.permissions`.

    Per-user shell init exports `NATS_URL` (loopback on the server, the
    server's host on clients) and points `NATS_NKEY` at the logged-in
    user's seed, so the `nats` CLI works directly.

    Bootstrap: run `clan vars generate` once per declared user pubkey
    before the first `clan machines update`. Pubkeys are committed under
    `vars/shared/`.
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
          monitoringPort = lib.mkOption {
            type = lib.types.port;
            default = 8222;
            description = "Monitoring HTTP port (/varz, /healthz). Bound to loopback only.";
          };
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open the client port in the firewall (monitoring stays loopback-only).";
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
          users = lib.mkOption {
            type = lib.types.attrsOf userType;
            default = { };
            description = ''
              Human users whose NKEY seeds get deployed to every machine
              they log into (share=true). Each user gets the broad-user
              default ACL unless overridden.
            '';
            example = lib.literalExpression "{ pinpox = { }; }";
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

  roles.client = {
    description = ''
      NATS client: installs the `nats` CLI plus the declared users' NKEY
      seeds and points NATS_URL at the server. No local nats-server.
    '';
    perInstance =
      {
        instanceName,
        roles,
        ...
      }:
      {
        nixosModule = import ./client.nix {
          inherit instanceName roles;
        };
      };
  };
}
