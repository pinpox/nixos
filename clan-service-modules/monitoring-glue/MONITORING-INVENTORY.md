# Monitoring inventory (pre-redesign snapshot)

Audit of everything the current monitoring stack collects, alerts on, and ships
— plus what is configured but dead. Captured 2026-09-18 from the repo
(`clan-service-modules/monitoring/*`, `inventory.nix:352-386`) and from the live
Prometheus on `porree` (`/api/v1/targets`, `/api/v1/status/config`,
`/api/v1/rules`, `/api/v1/alerts`, reachable over wg at
`https://vpn.prometheus.pablo.tools`).

**Live bottom line:** the stack is deployed but collects nothing. 4 scrape jobs:
2 with zero targets, 13 targets in `down`, 0 metrics ingested, all 14 alert
rules `inactive` for lack of data.

## Scrape jobs (Prometheus on porree, `127.0.0.1:9090`, retention `6GB`)

- `node-stats` — host metrics from node-exporter `:9100`, 1m interval
  - targets derived from `roles.node-exporter.machines`; `roles.node-exporter.tags.all` is **commented out** (`inventory.nix:357`)
  - live: `targets: []`; `:9100` connection-refused on porree, birne, kfbox, clementine, traube → node-exporter runs nowhere
  - node-exporter module (when enabled): extra collectors `cgroups`, `systemd`; textfile dir `/etc/nix`; firewall open on `wg-clan` only
- `blackbox` — HTTP `http_2xx` probe, 2m interval
  - target: `https://pablo.tools`
  - commented-out targets: megaclan3000.de, build.lounge.rocks, pass.pablo.tools (Vaultwarden), pinpox.github.io/nixos, cache.lounge.rocks nix-cache-info, news.0cx.de, git.0cx.de (Gitea), irc.0cx.de
  - live: **down**, `127.0.0.1:9115 connection refused` — `roles.blackbox.machines.porree` is **commented out** (`inventory.nix:384`)
  - probe module: GET, 5s timeout, HTTP/1.1+HTTP/2, 2xx only, follows redirects, verifies TLS, prefers ip4 with ip6 fallback
- `restic-exporter` — backup snapshot freshness, 1h interval, `/probe`
  - 12 targets auto-derived from `pinpox.services.restic-client.enable`: birne, clementine, fichte, kartoffel, kfbox, kiwi, limette, linse, mango, porree, tanne, traube (uconsole absent)
  - live: **all down**, `127.0.0.1:8080 connection refused` — flake module is imported on servers and its vars generator exists (`prometheus.nix:27`, `RESTIC_PASSWORD`/`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), but `services.restic-exporter.enable` is never set on porree
- `backup-reports` — json-exporter at `127.0.0.1:7979`, 1h interval, `/probe`
  - live: `targets: []` — `jsonTargets` defaults to `[]` and is never set; no json-exporter service exists anywhere in the repo
- Access path: Caddy → oauth2-proxy (Pocket ID, PKCE S256) at `prometheus.<clan-domain>`; plus VPN-only plain vhost `vpn.prometheus.pablo.tools` (`machines/porree/caddy.nix:185`)

## Active alert rules (14, all `inactive` — no data)

Source: `alert-rules.nix`. Device filter excludes `/var/lib/docker` and `/nix/store` paths.

- `filesystem_full_80percent` — root fs >80% used, for 10m
- `ram_using_90percent` — >90% RAM used, for 1h
- `swap_using_20percent` — >20% of swap used, for 30m
- `cpu_using_90percent` — >90% CPU, for 10m
- `oom_kills` — `increase(node_vmstat_oom_kill[5m]) > 0`
- `host_memory_under_memory_pressure` — major page faults >1000/s
- `reboot` — `node_boot_time_seconds < 300`
- `uptime` — up >30 days ("uptime monster")
- `systemd_service_failed` — any unit in state `failed`
- `host_down` — `up{job="node-stats"} == 0`, **excludes** `limette` and `kartoffel`
- `restic_backup_too_old` — latest restic snapshot older than 24h
- `http_status` — `probe_http_status_code != 200`, excludes `https://megaclan3000.de`
- `cert_expiry` — TLS cert expires in <30 days
- `flake_nixpkgs_outdated` — nixpkgs flake input not updated in 30 days
  - fed by `/etc/nix/flake_inputs.prom` (`modules/nix-common/default.nix:33`), emitting `flake_input_last_modified` per flake input, read via the node-exporter textfile collector

Default `for` is 2m unless the rule sets `time`.

## Alert rules present but commented out (~20)

- Self-monitoring: `prometheus_too_many_restarts`, `alert_manager_config_not_synced`, `alert_manager_e2e_dead_man_switch`, `prometheus_not_connected_to_alertmanager`, `prometheus_rule_evaluation_failures`, `prometheus_template_expansion_failures`, `alerts_silences_changed`
- Logs: `promtail_file_lagging`
- Storage: `filesystem_inodes_full`, `smart_errors` (S.M.A.R.T., skipping `Disabled` devices), `ext4_errors`, `unusual_disk_read_latency`, `unusual_disk_write_latency`
- Network/probes: `ping`, `ping_high_latency`, `http_match_failed`, `dns_query`, `secure_dns_query`, `connection_failed`, `healthchecks`
- Other: `daily_task_not_run`, `service_not_running`, `homeassistant` (persistent notifications)
- TODO block for backups: alert on "has not run", "no data for a week", "too old", "drastic file/size change"

## Notification path (live, up)

- Alertmanager bundled with Prometheus on `127.0.0.1:9093` (`/api/v2/status` → 200)
- Route: single receiver `all`, `group_by = [instance]`, `group_wait 30s`, `group_interval 2m`, `repeat_interval 24h`
- Webhook → matrix-hook on `127.0.0.1:11000/alert` → Matrix room `!ilXTQgAfoBlNBuDmsz:matrix.org` via matrix.org (`machines/porree/configuration.nix:74`)
- Email → `pinpox@pinpox.com` from `alertmanager@pinpox.com` via `mail.pinpox.com:465`, `send_resolved = true`, password from clan vars `alertmanager-smtp`
- VPN-only vhosts on porree: `vpn.alerts.pablo.tools` (alertmanager), `vpn.notify.pablo.tools` (matrix-hook)
- **Stale**: `environmentFile = /var/src/secrets/alertmanager/envfile` — pre-clan-vars path, likely nonexistent
- `alertmanager-irc-relay` role module exists (IRC relay + own system user) but is **not assigned** (`inventory.nix:385`)
- `modules/http2irc` — webhook→IRC relay, gated by `pinpox.services.monitoring-server.http-irc.enable`, enabled nowhere
- CLI alert viewer: `pt` shell alias → `promterm https://vpn.prometheus.pablo.tools/api/v1/alerts` (fish + zsh)

## Visualization / logs

- Grafana on porree at `status.<clan-domain>` (role default), OIDC-only via Pocket ID (`id.pablo.tools`, client `grafana`), local login form disabled, SMTP via `grafana@pinpox.com`, secret key from clan vars
- Datasources: Prometheus (first prometheus-role host) as default; Loki datasource only if a loki-role host exists → currently **absent**
- Dashboards are stateful in `/var/lib/grafana` (backed up offsite via restic); nothing provisioned declaratively
- Loki module written (`loki.nix`: port 3100, boltdb-shipper index, filesystem chunks, `/var/lib/loki` excluded from backup) but `roles.loki.machines.porree` is **commented out** (`inventory.nix:373`) → no log aggregation at all, no promtail/journald shipping anywhere

## Metric sources built but not wired into Prometheus

- home-assistant telemetry (`modules/home-assistant`): hass → influxdb-v2 line protocol → `services.telegraf` influxdb_v2_listener on `:8086` → `prometheus_client` output on `<wg-clan-ip>:9273`, namespace `hass`; firewall opens 9273 on wg. `pinpox.services.home-assistant.enable = false` on birne and set nowhere else, and **no scrape job targets `:9273`** regardless
- `fritzbox_exporter` — packaged in `overlays/default.nix`, no service uses it
- `mqtt2prometheus` — packaged in `overlays/default.nix`, no service uses it
- `smartmon-script` (`smartmon_*` metrics from smartmontools) — packaged, no systemd timer writes it to a textfile collector dir
- `config-hash` — per-machine deploy-drift detector (repo `configHashes.<host>` vs `/run/current-system/config-hash`, states clean/dirty/offline/stale/error). CLI-only, no metrics export; `dm-pull-deploy` is commented out (`inventory.nix:140-148`)
- `/run/current-system/flake-narhash` — always-available flake identifier intended for a NATS `nixos-reporter`; vars keys exist (`nats-key-nixos-reporter`, `nats-key-host-reporter`, `nats-key-ssh-logger`, `dm-pull-deploy-status-key`) but no reporter service is configured in this repo

## Machines in scope

- Tag `server`: birne, clementine, kfbox, porree, traube (`machine-type/server.nix` → `restic-client.enable = true`, journald capped at 1G, postgres backup when postgres runs)
- Tag `desktop`: mango, kiwi, tanne, fichte, kartoffel, limette, linse (`machine-type/desktop.nix` → `restic-client.enable = true`)
- Tag `mobile`: uconsole
- Monitoring server: porree (prometheus + alertmanager + grafana roles)

## Backup topology the restic metrics would cover

- `s3-onsite` → `s3:https://vpn.s3.pablo.tools/restic` (minio on birne)
- `s3-offsite` → `s3:https://s3.us-east-005.backblazeb2.com/pinpox-restic`
- Retention: `--keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 75`
- Per-service backup paths contributed by modules: grafana, loki (excluded), thelounge, vikunja, calibre-web, gitea, hedgedoc, nextcloud, opencloud, vaultwarden, home-assistant config, `/home`, `/root`, postgres dumps

## Ports / endpoints reference

| Component         | Address           | Exposure                                                                              |
| ----------------- | ----------------- | ------------------------------------------------------------------------------------- |
| Prometheus        | `127.0.0.1:9090`  | oauth2-proxy `:4180` → Caddy `prometheus.<clan-domain>`; `vpn.prometheus.pablo.tools` |
| Alertmanager      | `127.0.0.1:9093`  | `vpn.alerts.pablo.tools` (VPN IP-gated)                                               |
| matrix-hook       | `127.0.0.1:11000` | `vpn.notify.pablo.tools`                                                              |
| Grafana           | porree            | `status.<clan-domain>`, OIDC                                                          |
| node-exporter     | `:9100`           | firewall `wg-clan` only (not running)                                                 |
| blackbox-exporter | `:9115`           | firewall `wg-clan` only (not deployed)                                                |
| restic-exporter   | `:8080`           | localhost (not enabled)                                                               |
| json-exporter     | `:7979`           | expected by `backup-reports` job, does not exist                                      |
| Loki              | `:3100`           | firewall `wg-clan` only (not deployed)                                                |
| telegraf/hass     | `<wg-ip>:9273`    | firewall `wg-clan` (hass disabled)                                                    |

## Three-line revival (if the redesign wants the old behaviour back)

1. `inventory.nix:357` — uncomment `roles.node-exporter.tags.all` → revives 10 host rules + `host_down` + `flake_nixpkgs_outdated`
2. `inventory.nix:384` — uncomment `roles.blackbox.machines.porree` → revives `http_status` + `cert_expiry`
3. `prometheus.nix` — set `services.restic-exporter.enable = true` (env file from the existing `restic-exporter` vars generator) → revives `restic_backup_too_old`
