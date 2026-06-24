{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# ESPHome `/metrics` → NATS. Pull-based oneshot on a timer; runs as a
# DynamicUser. Owns its NKEY (declares the generator; seed lands only here)
# and hands it to the publisher via LoadCredential.
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;

  poller = pkgs.writeShellApplication {
    name = "nats-sensor-poller";
    runtimeInputs = with pkgs; [
      curl
      gawk
      natscli
      coreutils
    ];
    text = ''
      base="${settings.sensorUrl}"
      ts="$(date -u +%FT%TZ)"

      if ! metrics="$(curl -fsS --max-time 5 "$base/metrics")"; then
        echo "nats-sensor-poller: scrape of $base/metrics failed" >&2
        exit 0
      fi

      # Read one ESPHome /metrics gauge and publish it, skipping any reading
      # the device flags as failed.
      # shellcheck disable=SC2016
      emit() {
        # $1 = esphome metric id, $2 = nats subject, $3 = unit
        local failed value
        failed="$(awk -v id="$1" '$0 ~ "esphome_sensor_failed\\{id=\"" id "\"" { print $NF }' <<<"$metrics")"
        if [ "''${failed:-1}" != "0" ]; then
          echo "nats-sensor-poller: sensor $1 unavailable (failed=''${failed:-?})" >&2
          return
        fi
        value="$(awk -v id="$1" '$0 ~ "esphome_sensor_value\\{id=\"" id "\"" { print $NF }' <<<"$metrics")"
        if [ -z "$value" ]; then
          echo "nats-sensor-poller: sensor $1 produced no value" >&2
          return
        fi
        nats pub "$2" "{\"value\":$value,\"unit\":\"$3\",\"ts\":\"$ts\"}"
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          id: m: "      emit ${lib.escapeShellArg id} ${lib.escapeShellArg m.subject} ${lib.escapeShellArg m.unit} || true"
        ) settings.metrics
      )}
    '';
  };
in
{
  clan.core.vars.generators.${settings.keyGenerator} = import ../nats/nkey.nix {
    inherit pkgs;
    owner = "root";
  };

  systemd.services.nats-sensor-poller = {
    description = "Publish ESPHome sensor readings to NATS (${instanceName})";
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      LoadCredential = [ "nkey:${seedPath}" ];
      Environment = [
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=%d/nkey"
      ];
      ExecStart = lib.getExe poller;
    };
  };

  systemd.timers.nats-sensor-poller = {
    description = "Schedule ESPHome sensor polling (${instanceName})";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = settings.interval;
      Unit = "nats-sensor-poller.service";
    };
  };
}
