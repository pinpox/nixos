# Grafana-provisioned alert rules, ported from the old prometheus
# alert-rules.nix. Metrics come from the clan-core monitoring clients (alloy,
# collectors cpu/filesystem/meminfo/systemd) plus ./client-collectors.nix
# (vmstat/boottime/textfile).
#
# Dropped rules whose data sources don't exist anymore (and were already dead
# in the old stack): restic_backup_too_old (no restic-exporter), http_status
# and cert_expiry (no blackbox-exporter).
{ lib }:
let
  # Every expression filters (comparison operators drop non-matching series),
  # so a firing series always carries a value > 0 and a single shared
  # threshold expression works for all rules.
  mkRule =
    name:
    {
      condition,
      time ? "2m",
      description,
    }:
    {
      uid = name;
      title = name;
      condition = "fire";
      for = time;
      noDataState = "OK";
      execErrState = "Error";
      annotations.description = description;
      data = [
        {
          refId = "expr";
          datasourceUid = "mimir";
          relativeTimeRange = {
            from = 600;
            to = 0;
          };
          model = {
            refId = "expr";
            expr = condition;
            instant = true;
            intervalMs = 1000;
            maxDataPoints = 43200;
          };
        }
        {
          refId = "fire";
          datasourceUid = "__expr__";
          relativeTimeRange = {
            from = 0;
            to = 0;
          };
          model = {
            refId = "fire";
            type = "threshold";
            expression = "expr";
            conditions = [
              {
                type = "query";
                evaluator = {
                  type = "gt";
                  params = [ 0 ];
                };
                operator.type = "and";
                query.params = [ ];
                reducer = {
                  type = "last";
                  params = [ ];
                };
              }
            ];
          };
        }
      ];
    };
in
lib.mapAttrsToList mkRule {

  filesystem_full_80percent = {
    condition = ''100 - ((node_filesystem_avail_bytes{fstype!="rootfs",mountpoint="/"} * 100) / node_filesystem_size_bytes{fstype!="rootfs",mountpoint="/"}) > 80'';
    time = "10m";
    description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.mountpoint}} got less than 20% space left on its filesystem.";
  };

  swap_using_20percent = {
    condition = "node_memory_SwapTotal_bytes - (node_memory_SwapCached_bytes + node_memory_SwapFree_bytes) > node_memory_SwapTotal_bytes * 0.2";
    time = "30m";
    description = "{{$labels.instance}} is using 20% of its swap space for at least 30 minutes.";
  };

  ram_using_90percent = {
    condition = "node_memory_Buffers_bytes + node_memory_MemFree_bytes + node_memory_Cached_bytes < node_memory_MemTotal_bytes * 0.1";
    time = "1h";
    description = "{{$labels.instance}} is using at least 90% of its RAM for at least 1 hour.";
  };

  cpu_using_90percent = {
    condition = ''100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) >= 90'';
    time = "10m";
    description = "{{$labels.instance}} is running with cpu usage > 90% for at least 10 minutes: {{$value}}";
  };

  # The clan-core monitoring client filters node_systemd_unit_state to the
  # monitored services and renames it to nixos_systemd_unit_state.
  systemd_service_failed = {
    condition = ''nixos_systemd_unit_state{state="failed"} == 1'';
    description = "{{$labels.instance}} failed to (re)start service {{$labels.name}}.";
  };

  # Push model: there is no `up` metric. A host is down when it stopped
  # pushing; the subquery keeps the last seen sample timestamp for 2h so the
  # alert still fires after the series goes stale. limette and kartoffel are
  # switched off routinely.
  host_down = {
    condition = ''(time() - max by (instance) (max_over_time(timestamp(node_memory_MemTotal_bytes{instance!~"limette|kartoffel"})[2h:1m]))) > 900'';
    time = "5m";
    description = "{{$labels.instance}} has not pushed metrics for more than 15 minutes.";
  };

  oom_kills = {
    condition = "increase(node_vmstat_oom_kill[5m]) > 0";
    description = "{{$labels.instance}}: OOM kill detected";
  };

  host_memory_under_memory_pressure = {
    condition = "rate(node_vmstat_pgmajfault[1m]) > 1000";
    description = "{{$labels.instance}}: The node is under heavy memory pressure. High rate of major page faults: {{$value}}";
  };

  # The old rule compared the raw boot timestamp against 300 and could never
  # fire; compare the boot age instead.
  reboot = {
    condition = "time() - node_boot_time_seconds < 300";
    time = "0m";
    description = "{{$labels.instance}} just rebooted.";
  };

  uptime = {
    condition = "(time() - node_boot_time_seconds) / (60*60*24) > 30";
    description = "Uptime monster: {{$labels.instance}} has been up for more than 30 days.";
  };

  flake_nixpkgs_outdated = {
    condition = ''(time() - flake_input_last_modified{input="nixpkgs"}) / (60*60*24) > 30'';
    description = "Nixpkgs outdated: Nixpkgs on {{$labels.instance}} has not been updated in 30 days";
  };
}
