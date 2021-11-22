{ lib }:

let
  # docker's filesystems disappear quickly, leading to false positives
  deviceFilter = ''path!~"^(/var/lib/docker|/nix/store).*"'';
in
lib.mapAttrsToList
  (name: opts: {
    alert = name;
    expr = opts.condition;
    for = opts.time or "2m";
    labels = { };
    annotations.description = opts.description;
  })
  ({
    prometheus_too_many_restarts = {
      condition = ''changes(process_start_time_seconds{job=~"prometheus|alertmanager"}[15m]) > 2'';
      description = "Prometheus has restarted more than twice in the last 15 minutes. It might be crashlooping.";
    };

    alert_manager_config_not_synced = {
      condition = ''count(count_values("config_hash", alertmanager_config_hash)) > 1'';
      description = "Configurations of AlertManager cluster instances are out of sync.";
    };

    #alert_manager_e2e_dead_man_switch = {
    #  condition = "vector(1)";
    #  description = "Prometheus DeadManSwitch is an always-firing alert. It's used as an end-to-end test of Prometheus through the Alertmanager.";
    #};

    prometheus_not_connected_to_alertmanager = {
      condition = "prometheus_notifications_alertmanagers_discovered < 1";
      description = "Prometheus cannot connect the alertmanager\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
    };

    prometheus_rule_evaluation_failures = {
      condition = "increase(prometheus_rule_evaluation_failures_total[3m]) > 0";
      description = "Prometheus encountered {{ $value }} rule evaluation failures, leading to potentially ignored alerts.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
    };

    prometheus_template_expansion_failures = {
      condition = "increase(prometheus_template_text_expansion_failures_total[3m]) > 0";
      time = "0m";
      description = "Prometheus encountered {{ $value }} template text expansion failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
    };

    promtail_request_errors = {
      condition = ''100 * sum(rate(promtail_request_duration_seconds_count{status_code=~"5..|failed"}[1m])) by (namespace, job, route, instance) / sum(rate(promtail_request_duration_seconds_count[1m])) by (namespace, job, route, instance) > 10'';
      time = "15m";
      description = ''{{ $labels.job }} {{ $labels.route }} is experiencing {{ printf "%.2f" $value }}% errors.'';
    };

    promtail_file_lagging = {
      condition = ''abs(promtail_file_bytes_total - promtail_read_bytes_total) > 1e6'';
      time = "15m";
      description = ''{{ $labels.instance }} {{ $labels.job }} {{ $labels.path }} has been lagging by more than 1MB for more than 15m.'';
    };

    filesystem_full_80percent = {
      condition = ''disk_used_percent{mode!="ro"} >= 80'';
      time = "10m";
      description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.path}} got less than 20% space left on its filesystem.";
    };

    filesystem_inodes_full = {
      condition = ''disk_inodes_free / disk_inodes_total < 0.10'';
      time = "10m";
      description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.path}} got less than 10% inodes left on its filesystem.";
    };

    daily_task_not_run = {
      # give 6 hours grace period
      condition = ''time() - task_last_run{state="ok",frequency="daily"} > (24 + 6) * 60 * 60'';
      description = "{{$labels.host}}: {{$labels.name}} was not run in the last 24h";
    };

    daily_task_failed = {
      condition = ''task_last_run{state="fail"}'';
      description = "{{$labels.host}}: {{$labels.name}} failed to run";
    };
  # } // (lib.genAttrs [
  #   "borgbackup-turingmachine"
  #   "borgbackup-eve"
  #   "borgbackup-datastore"
  # ]
  #   (name: {
  #     condition = ''absent_over_time(task_last_run{name="${name}"}[1d])'';
  #     description = "status of ${name} is unknown: no data for a day";
  #   }))
  # // {

    # borgbackup_matchbox_not_run = {
    #   # give 6 hours grace period
    #   condition = ''time() - task_last_run{state="ok",frequency="daily",name="borgbackup-matchbox"} > 7 * 24 * 60 * 60'';
    #   description = "{{$labels.host}}: {{$labels.name}} was not run in the last week";
    # };

    # borgbackup_matchbox = {
    #   condition = ''absent_over_time(task_last_run{name="borgbackup-matchbox"}[7d])'';
    #   description = "status of borgbackup-matchbox is unknown: no data for a week";
    # };

    homeassistant = {
      condition = ''homeassistant_entity_available{domain="persistent_notification", entity!="persistent_notification.http_login"} >= 0'';
      description = "homeassistant notification {{$labels.entity}} ({{$labels.friendly_name}}): {{$value}}";
    };

    swap_using_30percent = {
      condition = "mem_swap_total - (mem_swap_cached + mem_swap_free) > mem_swap_total * 0.3";
      time = "30m";
      description = "{{$labels.host}} is using 30% of its swap space for at least 30 minutes.";
    };

    systemd_service_failed = {
      condition = ''systemd_units_active_code{name!~"nixpkgs-update-.*.service"} == 3'';
      description = "{{$labels.host}} failed to (re)start service {{$labels.name}}.";
    };

    # service_not_running = {
    #   condition = ''systemd_units_active_code{name=~"teamspeak3-server.service|tt-rss.service", sub!="running"}'';
    #   description = "{{$labels.host}} should have a running {{$labels.name}}.";
    # };

    ram_using_90percent = {
      condition = "mem_buffered + mem_free + mem_cached < mem_total * 0.1";
      time = "1h";
      description = "{{$labels.host}} is using at least 90% of its RAM for at least 1 hour.";
    };
    load15 = {
      condition = ''system_load15 / system_n_cpus{org!="nix-community"} >= 2.0'';
      time = "10m";
      description = "{{$labels.host}} is running with load15 > 1 for at least 5 minutes: {{$value}}";
    };
    reboot = {
      condition = "system_uptime < 300";
      description = "{{$labels.host}} just rebooted.";
    };
    uptime = {
      condition = ''system_uptime > 2592000'';
      description = "Uptime monster: {{$labels.host}} has been up for more than 30 days.";
    };
    ping = {
      condition = "ping_result_code{type!='mobile'} != 0";
      description = "{{$labels.url}}: ping from {{$labels.instance}} has failed!";
    };
    ping_high_latency = {
      condition = "ping_average_response_ms{type!='mobile'} > 5000";
      description = "{{$labels.instance}}: ping probe from {{$labels.source}} is encountering high latency!";
    };
    http = {
      condition = "http_response_result_code != 0";
      description = "{{$labels.server}} : http request failed from {{$labels.instance}}: {{$labels.result}}!";
    };
    http_match_failed = {
      condition = "http_response_response_string_match == 0";
      description = "{{$labels.server}} : http body not as expected; status code: {{$labels.status_code}}!";
    };
    dns_query = {
      condition = "dns_query_result_code != 0";
      description = "{{$labels.domain}} : could retrieve A record {{$labels.instance}} from server {{$labels.server}}: {{$labels.result}}!";
    };
    secure_dns_query = {
      condition = "secure_dns_state != 0";
      description = "{{$labels.domain}} : could retrieve A record {{$labels.instance}} from server {{$labels.server}}: {{$labels.result}} for protocol {{$labels.protocol}}!";
    };
    connection_failed = {
      condition = "net_response_result_code != 0";
      description = "{{$labels.server}}: connection to {{$labels.port}}({{$labels.protocol}}) failed from {{$labels.instance}}";
    };
    healthchecks = {
      condition = "hc_check_up == 0";
      description = "{{$labels.instance}}: healtcheck {{$labels.job}} fails!";
    };
    cert_expiry = {
      condition = "x509_cert_expiry < 7*24*3600";
      description = "{{$labels.instance}}: The TLS certificate from {{$labels.source}} will expire in less than 7 days: {{$value}}s";
    };

    public_runner_action_online = {
      condition = ''count(http_busy{name=~"runner.*", status="online"}) < 2'';
      description = "{{$labels.instance}}: There are no public github action runner registerd with github (see https://github.com/organizations/ls1-sys-prog-course/settings/actions)";
    };

    internal_runner_action_online = {
      condition = ''count(http_busy{name=~"internal-runner.*", status="online"}) < 1'';
      description = "{{$labels.instance}}: There are no interal github action runner registerd with github (see https://github.com/organizations/ls1-sys-prog-course-internal/settings/actions)";
    };

    postfix_queue_length = {
      condition = "avg_over_time(postfix_queue_length[1h]) > 10";
      description = "{{$labels.instance}}: postfix mail queue has undelivered {{$value}} items";
    };

    # ignore devices that disabled S.M.A.R.T (example if attached via USB)
    smart_errors = {
      condition = ''smart_device_health_ok{enabled!="Disabled"} != 1'';
      description = "{{$labels.instance}}: S.M.A.R.T reports: {{$labels.device}} ({{$labels.model}}) has errors.";
    };

    oom_kills = {
      condition = "increase(kernel_vmstat_oom_kill[5m]) > 0";
      description = "{{$labels.instance}}: OOM kill detected";
    };

    unusual_disk_read_latency = {
      condition = "rate(diskio_read_time[1m]) / rate(diskio_reads[1m]) > 0.1 and rate(diskio_reads[1m]) > 0";
      description = "{{$labels.instance}}: Disk latency is growing (read operations > 100ms)\n";
    };

    unusual_disk_write_latency = {
      condition = "rate(diskio_write_time[1m]) / rate(diskio_write[1m]) > 0.1 and rate(diskio_write[1m]) > 0";
      description = "{{$labels.instance}}: Disk latency is growing (write operations > 100ms)\n";
    };

    host_memory_under_memory_pressure = {
      condition = "rate(node_vmstat_pgmajfault[1m]) > 1000";
      description = "{{$labels.instance}}: The node is under heavy memory pressure. High rate of major page faults: {{$value}}";
    };

    ext4_errors = {
      condition = "ext4_errors_value > 0";
      description = "{{$labels.instance}}: ext4 has reported {{$value}} I/O errors: check /sys/fs/ext4/*/errors_count";
    };

    alerts_silences_changed = {
      condition = ''abs(delta(alertmanager_silences{state="active"}[1h])) >= 1'';
      description = "alertmanager: number of active silences has changed: {{$value}}";
    };
  })
