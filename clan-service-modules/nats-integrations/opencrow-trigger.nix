{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# NATS → opencrow trigger-pipe bridge. Subscribes to subjects and writes one
# prompt line per message into a persona's trigger pipe, waking the agent.
#
# Unlike the other roles this declares NO key of its own: it reuses the
# persona's NKEY (nats-key-opencrow-<instance>, declared and deployed by the
# co-located @pinpox/opencrow instance). It runs as root to read that
# root-owned seed and to write the container-owned FIFO. The subscribed
# subjects MUST be in that key's subscribe.allow (they are — a subject pushed
# to the pipe is by definition one the persona may read).
let
  # The persona's own key, declared and deployed by the co-located opencrow instance.
  keyGenerator = "nats-key-opencrow-${settings.instance}";
  seedPath = config.clan.core.vars.generators.${keyGenerator}.files.seed.path;
  pipePath = "/var/lib/opencrow-${settings.instance}/sessions/trigger.pipe";
  containerUnit = "container@opencrow-${settings.instance}.service";

  mkService = name: sub: {
    name = "nats-opencrow-trigger-${settings.instance}-${name}";
    value = {
      description = "Pipe NATS ${sub.subject} → opencrow-${settings.instance} trigger (${instanceName})";
      after = [
        "network-online.target"
        "nats.service"
        containerUnit
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        NATS_URL = settings.natsUrl;
        NATS_NKEY = seedPath;
        SUBJECT = sub.subject;
        PROMPT = sub.prompt;
        PIPE = pipePath;
      };
      serviceConfig = {
        # Root: reads the root-owned seed and writes the container-owned FIFO.
        Restart = "always";
        RestartSec = "5s";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "nats-opencrow-trigger-${settings.instance}-${name}";
            runtimeInputs = with pkgs; [
              natscli
              coreutils
            ];
            text = ''
              # One message body per line — publish single-line payloads. Each
              # line becomes one trigger = one agent turn, so only wire rare,
              # decision-grade subjects here. `{{payload}}` in PROMPT is replaced
              # with the message body. Messages arriving while the agent is
              # down are dropped (core NATS has no history).
              nats sub --raw "$SUBJECT" | while IFS= read -r payload; do
                if [ -n "$payload" ] && [ -p "$PIPE" ]; then
                  line=''${PROMPT//"{{payload}}"/"$payload"}
                  printf '%s\n' "$line" > "$PIPE"
                fi
              done
            '';
          }
        );
      };
    };
  };
in
{
  systemd.services = lib.listToAttrs (lib.mapAttrsToList mkService settings.subscriptions);
}
