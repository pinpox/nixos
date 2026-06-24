{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# SSH auth-event logger → NATS, for security/attack-pattern analysis. Follows
# the sshd journal (OpenSSH 9.8+ logs auth under `sshd-session`; we also match
# `sshd`/`sshd-auth` for other versions/splits), classifies each line, and
# publishes to `<root>.<hostname>.ssh.<event>` with the parsed IP + the raw
# message (the AI's source of truth). Uses the `nats` CLI (native NKEY auth)
# per event — fine for realistic scan volume (a few events/sec). If a host
# ever sees sustained high-rate floods, swap in a persistent-connection
# publisher. Long-running; DynamicUser + journal group + LoadCredential.
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;
  host = config.networking.hostName;

  logger = pkgs.writeShellApplication {
    name = "nats-ssh-logger";
    runtimeInputs = with pkgs; [
      systemd
      gnused
      jq
      coreutils
      natscli
    ];
    text = ''
      journalctl -f -n0 -o cat -t sshd -t sshd-session -t sshd-auth | while IFS= read -r msg; do
        user=""
        case "$msg" in
          "Accepted "*)      event=accepted; user="$(sed -nE 's/.* for ([^ ]+) from .*/\1/p' <<<"$msg")" ;;
          "Failed "*)        event=failed;   user="$(sed -nE 's/.* for (invalid user )?([^ ]+) from .*/\2/p' <<<"$msg")" ;;
          "Invalid user "*)  event=invalid;  user="$(sed -nE 's/^Invalid user ([^ ]+) .*/\1/p' <<<"$msg")" ;;
          "Connection closed by "* | "Connection reset by "*) event=closed ;;
          "Disconnected from "* | "Received disconnect from "*) event=disconnect; user="$(sed -nE 's/.*(invalid user |authenticating user |user )([^ ]+) [0-9].*/\2/p' <<<"$msg")" ;;
          *"maximum authentication attempts exceeded"*) event=maxauth; user="$(sed -nE 's/.* for ([^ ]+) from .*/\1/p' <<<"$msg")" ;;
          *) continue ;;
        esac
        ip="$(sed -nE 's/.* ([^ ]+) port [0-9]+.*/\1/p' <<<"$msg")"
        payload="$(jq -cn \
          --arg event "$event" --arg user "$user" --arg ip "$ip" \
          --arg host "${host}" --arg msg "$msg" --arg ts "$(date -u +%FT%TZ)" \
          '{event: $event, user: $user, ip: $ip, host: $host, msg: $msg, ts: $ts}')"
        nats pub "host.${host}.ssh.$event" "$payload" || true
      done
    '';
  };
in
{
  clan.core.vars.generators.${settings.keyGenerator} = import ../nats/nkey.nix {
    inherit pkgs;
    owner = "root";
  };

  systemd.services.nats-ssh-logger = {
    description = "Publish sshd auth events to NATS (${instanceName})";
    after = [
      "network-online.target"
      "nats.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      SupplementaryGroups = [ "systemd-journal" ]; # read the journal
      LoadCredential = [ "nkey:${seedPath}" ];
      Environment = [
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=%d/nkey"
      ];
      ExecStart = lib.getExe logger;
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
