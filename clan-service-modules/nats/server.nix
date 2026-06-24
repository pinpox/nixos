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
# Server role: runs nats-server and authorizes a set of public keys. It owns
# NO identity seeds — each entry in `settings.authorizations` names a clan
# vars generator whose committed `pub` it reads. The only key it generates is
# its own internal `jsadmin` (for the stream-convergence oneshot), and only
# when streams are declared.
let
  cfg = settings;
  auth = import ./auth.nix { inherit lib clanLib; };

  authUsers = auth.mkAuthorizationUsers {
    flake = config.clan.core.settings.directory;
    authorizations = cfg.authorizations;
  };

  # Retention is opt-in: with no streams declared, none of the machinery below
  # (the jsadmin identity + the convergence oneshot) is deployed.
  hasStreams = cfg.streams != { };

  jsadminGen = "nats-${instanceName}-jsadmin";
  jsadminSeed = config.clan.core.vars.generators.${jsadminGen}.files.seed.path;
  jsadminPub = auth.readPub {
    flake = config.clan.core.settings.directory;
    generator = jsadminGen;
  };

  streamConfigFile =
    name: s:
    pkgs.writeText "nats-stream-${name}.json" (
      builtins.toJSON {
        inherit name;
        inherit (s) subjects;
        retention = "limits";
        discard = "old";
        max_age = s.maxAge * 1000000000;
        max_bytes = s.maxBytes;
        max_msgs = -1;
        storage = "file";
        num_replicas = 1;
      }
    );

  streamConverge = pkgs.writeShellApplication {
    name = "nats-streams-converge";
    runtimeInputs = with pkgs; [
      natscli
      coreutils
    ];
    text = ''
      ready=0
      for _ in $(seq 1 60); do
        if nats stream ls >/dev/null 2>&1; then
          ready=1
          break
        fi
        sleep 1
      done
      if [ "$ready" != 1 ]; then
        echo "nats-streams-converge: server/JetStream not ready" >&2
        exit 1
      fi

      upsert() {
        # $1 = stream name, $2 = StreamConfig JSON file
        if nats stream info "$1" >/dev/null 2>&1; then
          echo "nats-streams-converge: updating $1"
          nats stream update "$1" --config "$2" -f
        else
          echo "nats-streams-converge: creating $1"
          nats stream add "$1" --config "$2"
        fi
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: s: "      upsert ${lib.escapeShellArg name} ${streamConfigFile name s}") cfg.streams
      )}
    '';
  };
in
{
  environment.systemPackages = [ pkgs.natscli ];

  # The server's only generated key is jsadmin (convergence oneshot), gated on
  # streams. Every other identity is authorized by reading its pub; its seed
  # lives wherever the owning role runs.
  clan.core.vars.generators = lib.mkMerge (
    lib.optional hasStreams {
      ${jsadminGen} = import ./nkey.nix {
        inherit pkgs;
        owner = "root";
      };
    }
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
        # unauthenticated, so they must never be exposed off-box.
        http = "127.0.0.1:${toString cfg.monitoringPort}";
        authorization.users = authUsers ++ lib.optionals hasStreams [
          {
            nkey = jsadminPub;
            permissions = {
              publish.allow = [ "$JS.API.>" ];
              subscribe.allow = [ "_INBOX.>" ];
            };
          }
        ];
      }
      cfg.extraSettings
    ];
  };

  # Converge declarative JetStream streams once the server is up — only when
  # streams are declared. Idempotent add/update via the jsadmin NKEY;
  # DynamicUser with the seed handed in through LoadCredential.
  systemd.services = lib.mkIf hasStreams {
    nats-streams-converge = {
      description = "Converge declarative NATS JetStream streams";
      after = [ "nats.service" ];
      requires = [ "nats.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        LoadCredential = [ "nkey:${jsadminSeed}" ];
        Environment = [
          "NATS_URL=nats://127.0.0.1:${toString cfg.clientPort}"
          "NATS_NKEY=%d/nkey"
        ];
        ExecStart = lib.getExe streamConverge;
      };
    };
  };
}
