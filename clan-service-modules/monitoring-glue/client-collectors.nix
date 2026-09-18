# Extra Alloy pipeline for collectors the clan-core monitoring client doesn't
# enable: vmstat (OOM kills, page-fault pressure), stat (node_boot_time_seconds
# on Linux, for the reboot/uptime alerts; "boottime" is BSD-only) and the
# textfile collector reading /etc/nix/flake_inputs.prom (written by
# modules/nix-common) for the flake-freshness alert.
#
# Wired via extraModules on the clan-core monitoring client role, so it
# applies to every monitored machine. Alloy loads all *.alloy files from
# /etc/alloy; component names carry an _extra suffix to avoid clashing with
# the generated config.alloy. The mimir credentials are the same ones the
# clan-core client already loads into the alloy unit.
{ config, ... }:
{
  environment.etc."alloy/extra-collectors.alloy".text = ''
    prometheus.exporter.unix "extra" {
      set_collectors = ["vmstat", "stat", "textfile"]
      textfile {
        directory = "/etc/nix"
      }
    }

    prometheus.scrape "extra" {
      targets = prometheus.exporter.unix.extra.targets
      forward_to = [prometheus.remote_write.mimir_extra.receiver]
      scrape_interval = "60s"
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
}
