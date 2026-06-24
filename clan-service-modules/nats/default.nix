{ clanLib, lib, ... }:
# NATS broker + authorization. The server is a pure authorizer: it takes a set
# of `authorizations` (each = a public-key generator reference + an ACL) and
# nothing else about identity. It holds no seeds.
#
# Key material lives with whoever uses it: the `client` role deploys human
# login keys (so the CLI works in your shell on every machine), and each
# @pinpox/nats-integrations role declares its own workload key. Both import
# ./nkey.nix, so a key's secret seed exists only on the machines that run its
# role, while the public key is committed and authorized here.
let
  auth = import ./auth.nix { inherit lib clanLib; };

  # One server authorization: a public-key generator + the subjects it may use.
  # `keyGenerator` defaults to `nats-key-<name>` (the attribute name), matching
  # the convention used by client login users and integration roles, so an
  # authorization usually needs only its `permissions`.
  authorizationType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        keyGenerator = lib.mkOption {
          type = lib.types.str;
          default = "nats-key-${name}";
          description = ''
            Name of the clan vars generator whose `pub` file holds this
            identity's NKEY public key (share=true). Defaults to
            `nats-key-<name>` (the attribute name). The generator is declared
            by the role that uses the seed (client role for humans, an
            nats-integrations role for a workload).
          '';
        };
        permissions = lib.mkOption {
          type = auth.permissionsBlock;
          default = { };
          description = "Allowed/denied publish & subscribe subjects for this key.";
        };
      };
    }
  );

  # A declarative JetStream stream. Subjects MUST be disjoint from every other
  # stream in the instance: JetStream rejects overlapping streams, and a
  # literal `>` catch-all needs no-ack and would block every override.
  streamType = lib.types.submodule {
    options = {
      subjects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Subjects this stream captures (must not overlap any other stream).";
        example = lib.literalExpression ''[ "home.rooms.study.>" ]'';
      };
      maxAge = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 604800;
        description = "Retention by age, in seconds (0 = unlimited). Default 604800 = 7 days.";
      };
      maxBytes = lib.mkOption {
        type = lib.types.int;
        default = -1;
        description = "Max on-disk size in bytes (-1 = unlimited).";
      };
    };
  };
in
{
  _class = "clan.service";
  manifest.name = "nats";
  manifest.description = "NATS broker that authorizes a set of public keys.";
  manifest.readme = ''
    Two roles:

      - server: runs nats-server with JetStream. A pure authorizer — it takes
        `authorizations` (each names a public-key generator + an ACL), reads
        each committed `pub`, and builds the nats `authorization.users` list.
        It generates/holds no identity seeds. Client port (4222) is reachable
        on the clan network when `openFirewall`; monitoring (8222) is loopback.
      - client: installs the `nats` CLI, points `NATS_URL` at the server, and
        deploys the human login identities in `loginUsers` (NKEY seed owned by
        the matching Unix login, share=true, so the CLI works in your shell).

    Identities. Every identity is one Ed25519 NKEY (see ./nkey.nix). Its
    secret seed is deployed only to the machines that DECLARE the generator —
    a login machine (client role) or the single machine an integration role
    runs on. Its public key is committed under vars/shared/ and authorized on
    the server. So an app key never lands on a host that doesn't run its
    workload; the server never holds any seed.

    To add a publisher: declare its key generator in the owning role (a
    @pinpox/nats-integrations role, via ./nkey.nix) and add a matching
    `authorizations.<name> = { keyGenerator; permissions; }` entry here.

    Retention is opt-in via `roles.server.settings.streams` (see streamType);
    the first declared stream also provisions the jsadmin identity + a
    convergence oneshot.

    Bootstrap: `clan vars generate` once (creates seeds + pubs) before the
    first `clan machines update`. Pubkeys are committed under vars/shared/.
  '';
  manifest.categories = [ "Network" ];
  manifest.exports.out = [ "endpoints" ];

  roles.server = {
    description = "NATS hub: nats-server with JetStream; authorizes public keys.";
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
          authorizations = lib.mkOption {
            type = lib.types.attrsOf authorizationType;
            default = { };
            description = ''
              Public keys the server authorizes, each with its ACL. The seed
              for each lives wherever its owning role runs; here you only
              reference the key (by generator) and grant topics.
            '';
            example = lib.literalExpression ''
              { host-reporter = { keyGenerator = "nats-key-host-reporter"; permissions.publish.allow = [ "host.>" ]; }; }
            '';
          };
          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Free-form passthrough merged into `services.nats.settings`.";
          };
          streams = lib.mkOption {
            type = lib.types.attrsOf streamType;
            default = { };
            description = ''
              Declarative JetStream streams to converge. Empty (default) →
              nothing is retained. Subjects must be disjoint across streams.
              Declaring any stream provisions the jsadmin identity + the
              convergence oneshot.
            '';
            example = lib.literalExpression ''
              { sensors-archive = { subjects = [ "sensors.>" ]; maxAge = 31536000; }; }
            '';
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
      NATS client: installs the `nats` CLI, points NATS_URL at the server, and
      deploys the human login identities in `loginUsers`. No local nats-server.
    '';
    interface =
      { lib, ... }:
      {
        options.loginUsers = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule { options = { }; });
          default = { };
          description = ''
            Human login identities to deploy on every client: each gets an
            NKEY whose seed is owned by the matching Unix login (generator
            `nats-key-<name>`, share=true) plus shell env pointing the `nats`
            CLI at it. Authorize them in the server's `authorizations`.
          '';
          example = lib.literalExpression "{ pinpox = { }; }";
        };
      };
    perInstance =
      {
        instanceName,
        settings,
        roles,
        ...
      }:
      {
        nixosModule = import ./client.nix {
          inherit instanceName settings roles;
        };
      };
  };
}
