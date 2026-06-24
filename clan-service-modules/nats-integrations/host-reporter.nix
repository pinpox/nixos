{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# Machine lifecycle reporter. One RemainAfterExit oneshot per machine:
# ExecStart publishes an "up" event on boot, ExecStop publishes "down" during
# clean shutdown/reboot. Owns its NKEY (declares the generator, share=true —
# one host-reporter key cluster-wide). Note: a crash/power-loss fires no
# "down"; detect those via an "up" carrying a fresh boot_id with no preceding
# "down".
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;
  host = config.networking.hostName;

  reporter = pkgs.writeShellApplication {
    name = "nats-host-reporter";
    runtimeInputs = with pkgs; [
      natscli
      coreutils
    ];
    text = ''
      state="$1"
      ts="$(date -u +%FT%TZ)"
      boot_id="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
      payload="{\"state\":\"$state\",\"host\":\"${host}\",\"boot_id\":\"$boot_id\",\"ts\":\"$ts\"}"

      if [ "$state" = up ]; then
        # Retry a little to ride out mesh/DNS settling on a cold boot.
        for _ in $(seq 1 10); do
          if nats pub "host.${host}.status" "$payload"; then
            exit 0
          fi
          sleep 3
        done
        echo "nats-host-reporter: failed to publish up event" >&2
      else
        # Best-effort + time-bounded so it never stalls shutdown.
        timeout 8 nats pub "host.${host}.status" "$payload" || true
      fi
    '';
  };
in
{
  clan.core.vars.generators.${settings.keyGenerator} = import ../nats/nkey.nix {
    inherit pkgs;
    owner = "root";
  };

  systemd.services.nats-host-reporter = {
    description = "Report machine up/down to NATS (${instanceName})";
    after = [
      "network-online.target"
      "nats.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Runs as root (no DynamicUser): ExecStop fires at shutdown, long after
      # ExecStart — a DynamicUser would get a fresh UID there that can't read
      # the credential the ExecStart UID owned. Root reads the root-owned seed
      # directly and is stable across both.
      Environment = [
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=${seedPath}"
      ];
      ExecStart = "${lib.getExe reporter} up";
      ExecStop = "${lib.getExe reporter} down";
      TimeoutStopSec = "15s";
    };
  };
}
