# Extra Alloy pipeline for collectors the clan-core monitoring client doesn't
# enable: vmstat (OOM kills, page-fault pressure), stat (node_boot_time_seconds
# on Linux, for the uptime alert; "boottime" is BSD-only) and the
# textfile collector reading /var/lib/prometheus-textfile:
#   - flake_inputs.prom, symlinked from /etc/nix (written by modules/nix-common)
#     for the flake_nixpkgs_outdated/flake_nixpkgs_age_missing alerts
#   - restic-<backup>.prom, stamped by modules/restic on backup success
#   - reboot.prom, written by reboot-required.service below for the
#     reboot_pending alert
#
# Wired via extraModules on the clan-core monitoring client role, so it
# applies to every monitored machine. Alloy loads all *.alloy files from
# /etc/alloy; component names carry an _extra suffix to avoid clashing with
# the generated config.alloy. The mimir credentials are the same ones the
# clan-core client already loads into the alloy unit.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-textfile 0755 root root -"
    "L+ /var/lib/prometheus-textfile/flake_inputs.prom - - - - /etc/nix/flake_inputs.prom"
  ];

  # Compares the kernel and modules the host booted with those of the active
  # system. The restart triggers rerun it on every switch that changes either,
  # so a deploy reports at once and a switch back to the booted kernel clears
  # it. `since` survives reruns, so the alert can wait for a convenient reboot
  # after a deploy.
  systemd.services.reboot-required = {
    description = "Record whether a reboot is pending for an installed kernel";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    restartTriggers = [
      config.boot.kernelPackages.kernel
      config.system.modulesTree
    ];
    path = [
      pkgs.coreutils
      pkgs.gnused
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      out=/var/lib/prometheus-textfile/reboot.prom
      same() { [ "$(readlink -f "/run/booted-system/$1")" = "$(readlink -f "/run/current-system/$1")" ]; }
      booted=$(uname -r)
      installed=$(ls /run/current-system/kernel-modules/lib/modules)
      {
        echo '# HELP reboot_required 1 if the active system has a different kernel or kernel modules than the host booted with.'
        echo '# TYPE reboot_required gauge'
        if same kernel && same kernel-modules; then
          echo "reboot_required 0"
        else
          since=$(sed -n 's/^reboot_required_since_timestamp_seconds{[^}]*} //p' "$out" 2>/dev/null || true)
          echo "reboot_required 1"
          echo '# HELP reboot_required_since_timestamp_seconds When the pending reboot was first recorded.'
          echo '# TYPE reboot_required_since_timestamp_seconds gauge'
          echo "reboot_required_since_timestamp_seconds{booted=\"$booted\",installed=\"$installed\"} ''${since:-$(date +%s)}"
        fi
      } > "$out.tmp"
      mv "$out.tmp" "$out"
    '';
  };

  environment.etc."alloy/extra-collectors.alloy".text = ''
    prometheus.exporter.unix "extra" {
      set_collectors = ["vmstat", "stat", "textfile"]
      textfile {
        directory = "/var/lib/prometheus-textfile"
      }
    }

    prometheus.scrape "extra" {
      targets = prometheus.exporter.unix.extra.targets
      forward_to = [prometheus.relabel.extra.receiver]
      scrape_interval = "60s"
    }

    // The clan-core local_system exporter already emits node_exporter_build_info
    // with identical labels; a second writer makes mimir reject every other
    // sample of it as out-of-order.
    prometheus.relabel "extra" {
      forward_to = [prometheus.remote_write.mimir_extra.receiver]
      rule {
        action = "drop"
        source_labels = ["__name__"]
        regex = "node_exporter_build_info"
      }
    }

    prometheus.remote_write "mimir_extra" {
      endpoint {
        url = "https://status.pin/mimir/api/v1/push"
        basic_auth {
          username = "${config.clan.core.vars.generators.mimir-auth.files.username.value}"
          password_file = sys.env("CREDENTIALS_DIRECTORY") + "/mimir-auth-password"
        }
      }
    }
  '';

  # Caddy access logs with GeoIP. The clan-core journal pipeline has no
  # processing hook, so caddy.service is dropped there (see the client role's
  # afterNormalization rule in inventory.nix) and shipped by this pipeline
  # instead, with the same instance/service_name/level labels plus the
  # client's country/city/coordinates as structured metadata (queryable, not
  # indexed). DB-IP City Lite ships in nixpkgs and needs no account; private
  # and unknown addresses simply get no metadata.
  environment.etc."alloy/caddy-logs.alloy" = lib.mkIf config.services.caddy.enable {
    text = ''
      loki.source.journal "caddy" {
        matches = "_SYSTEMD_UNIT=caddy.service"
        relabel_rules = loki.relabel.caddy.rules
        forward_to = [loki.process.caddy.receiver]
      }

      loki.relabel "caddy" {
        rule {
          source_labels = ["__journal__hostname"]
          target_label = "instance"
        }
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label = "service_name"
        }
        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label = "level"
        }
        forward_to = []
      }

      loki.process "caddy" {
        stage.json {
          expressions = { client_ip = "request.client_ip" }
        }
        stage.geoip {
          source = "client_ip"
          db = "${pkgs.dbip-city-lite}/share/dbip/dbip-city-lite.mmdb"
          db_type = "city"
        }
        stage.structured_metadata {
          values = {
            country = "geoip_country_code",
            country_name = "geoip_country_name",
            city = "geoip_city_name",
            lat = "geoip_location_latitude",
            lon = "geoip_location_longitude",
          }
        }
        forward_to = [loki.write.caddy.receiver]
      }

      loki.write "caddy" {
        endpoint {
          url = "https://status.pin/loki/loki/api/v1/push"
          basic_auth {
            username = "${config.clan.core.vars.generators.loki-auth.files.username.value}"
            password_file = sys.env("CREDENTIALS_DIRECTORY") + "/loki-auth-password"
          }
        }
      }
    '';
  };
}
