# Grafana-provisioned alert rules, ported from the old prometheus
# alert-rules.nix. Metrics come from the clan-core monitoring clients (alloy,
# collectors cpu/filesystem/meminfo/systemd), ./client-collectors.nix
# (vmstat/boottime/textfile) and the blackbox probes in ./default.nix.
#
# restic_backup_too_old is now fed by the success stamp modules/restic writes
# for the textfile collector instead of the (never enabled) restic-exporter.
{ lib, servers }:
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

  filesystem_full_90percent = {
    condition = ''100 - ((node_filesystem_avail_bytes{fstype!="rootfs",mountpoint="/"} * 100) / node_filesystem_size_bytes{fstype!="rootfs",mountpoint="/"}) > 90'';
    time = "10m";
    description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.mountpoint}} got less than 10% space left on its filesystem.";
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

  # restic units are not `services.<x>.enable` services, so they are missing
  # from nixos_systemd_unit_state; the raw metric reaches mimir as well.
  restic_backup_failed = {
    condition = ''node_systemd_unit_state{name=~"restic-backups-.*\\.service", state="failed"} == 1'';
    description = "{{$labels.instance}}: backup unit {{$labels.name}} failed.";
  };

  # Stamp written on successful completion (backup + prune); timers run
  # daily. Every restic unit a host reports (node_systemd_unit_state) must
  # have a stamp, so a backup that never succeeded fires too: the failed unit
  # state is reset by every deploy or reboot and can't be relied on alone.
  # The 1h windows span the scrape gap of an Alloy restart on deploy; hosts
  # that are off stop reporting both and stay silent.
  restic_backup_too_old = {
    condition = ''
      (time() - max by (instance, backup) (last_over_time(restic_backup_last_success_timestamp_seconds[1h]))) / (60*60) > 36
      or
      (
        max by (instance, backup) (label_replace(last_over_time(node_systemd_unit_state{name=~"restic-backups-.+\\.service"}[1h]), "backup", "$1", "name", "restic-backups-(.+)\\.service"))
        unless on(instance, backup) last_over_time(restic_backup_last_success_timestamp_seconds[1h])
      )
    '';
    time = "1h";
    description = "{{$labels.instance}}: no successful {{$labels.backup}} backup in the last 36 hours (or none recorded at all).";
  };

  # Push model: there is no `up` metric. A host is down when it stopped
  # pushing; the subquery keeps the last seen sample timestamp for 2h so the
  # alert still fires after the series goes stale. Restricted to the
  # server-tagged machines (`servers`): desktops and mobiles are switched off
  # routinely and must not page.
  host_down = {
    condition = ''(time() - max by (instance) (max_over_time(timestamp(node_memory_MemTotal_bytes{instance=~"${lib.concatStringsSep "|" servers}"})[2h:1m]))) > 900'';
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

  uptime = {
    condition = "(time() - node_boot_time_seconds) / (60*60*24) > 30";
    description = "Uptime monster: {{$labels.instance}} has been up for more than 30 days.";
  };

  # A deploy that changes the kernel installs it for the next boot only
  # (reboot-required.service in ./client-collectors.nix). A week leaves room
  # to reboot at a convenient time before paging.
  reboot_pending = {
    condition = "time() - max by (instance, booted, installed) (reboot_required_since_timestamp_seconds) > 604800 and on(instance) max by (instance) (reboot_required) == 1";
    time = "0m";
    description = "{{$labels.instance}} installed kernel {{$labels.installed}} but still runs {{$labels.booted}}: reboot it.";
  };

  # flake_input_last_modified (modules/nix-common) is the commit time of the
  # nixpkgs a host was built from, fixed at build time: it only moves when a
  # flake.lock bump is deployed there, so this fires whether nobody bumped the
  # lock or the bump never reached the host.
  #
  # Restricted to the server-tagged machines (`servers`): desktops and
  # laptops are online only now and then, so an alert for them either
  # resolves falsely whenever they go offline or keeps paging while they
  # cannot be deployed to. Their age stays visible on the Overview dashboard.
  # The rule reads each server's last value from the past hour: a deploy
  # restarts Alloy, leaving up to one scrape without samples, and the old
  # rev's series (rev/narHash labels) lingers in the window; max by instance
  # lets the newest commit win.
  flake_nixpkgs_outdated = {
    condition = ''time() - max by (instance) (last_over_time(flake_input_last_modified{input="nixpkgs",instance=~"${lib.concatStringsSep "|" servers}"}[1h])) > 14 * 86400'';
    time = "0m";
    description = "{{$labels.instance}} runs nixpkgs committed {{ humanizeDuration $values.expr.Value }} ago: bump flake.lock and redeploy.";
  };

  # Host pushes metrics but no nixpkgs age, so its age cannot be judged
  # (textfile missing or the collector pipeline broken). Hosts that are off
  # stop pushing node metrics too and stay silent. The 1h window spans the
  # scrape gap of an Alloy restart on deploy; `for` spans the boot of a host
  # that was off for longer, where node metrics can arrive up to one 60s
  # textfile scrape before the nixpkgs series.
  flake_nixpkgs_age_missing = {
    condition = ''max by (instance) (last_over_time(node_memory_MemTotal_bytes[1h])) unless on(instance) last_over_time(flake_input_last_modified{input="nixpkgs"}[1h])'';
    time = "10m";
    description = "{{$labels.instance}} is up but has not reported flake_input_last_modified for nixpkgs in the past hour.";
  };

  # Blackbox probes (settings.probes); `target` is the probed URL. Both
  # expressions are > 0 exactly when unhealthy (probe_http_status_code is 0
  # on connection failure, so it can't be used as the firing value).
  probe_failed = {
    condition = "1 - probe_success";
    time = "5m";
    description = "Probe of {{$labels.target}} failed (non-200, TLS error or unreachable) for 5 minutes.";
  };

  cert_expiry = {
    condition = "30 - (probe_ssl_earliest_cert_expiry - time()) / (60*60*24)";
    time = "1h";
    description = "TLS certificate of {{$labels.target}} expires in less than 30 days.";
  };
}
