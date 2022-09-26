{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.monitoring-server.loki;
  port-loki = 3100;
in
{

  options.pinpox.services.monitoring-server.loki = {
    enable = mkEnableOption "Loki log collector";
  };

  config = mkIf cfg.enable {

    networking.firewall = {
      enable = true;
      interfaces.wg0.allowedTCPPorts = [ port-loki ];
    };

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = { http_listen_port = port-loki; };

        ingester = {
          lifecycler = {
            address = "0.0.0.0";
            ring = {
              kvstore = { store = "inmemory"; };
              replication_factor = 1;
            };
            final_sleep = "0s";
          };

          # Any chunk not receiving new logs in this time will be flushed
          chunk_idle_period = "1h";

          # All chunks will be flushed when they hit this age, default is 1h
          max_chunk_age = "1h";
          # Loki will attempt to build chunks up to 1.5MB, flushing first if
          # chunk_idle_period or max_chunk_age is reached first
          chunk_target_size = 1048576;

          # Must be greater than index read cache TTL if using an index cache (Default
          # index read cache TTL is 5m)
          chunk_retain_period = "30s";

          # Chunk transfers disabled
          max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {

          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";

            # Can be increased for faster performance over longer query periods,
            # uses more disk space
            cache_ttl = "24h";

            shared_store = "filesystem";
          };

          filesystem = { directory = "/var/lib/loki/chunks"; };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        chunk_store_config = { max_look_back_period = "0s"; };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki/boltdb-shipper-compactor";
          shared_store = "filesystem";
        };
      };
    };

    # Exclude loki directory from backup
    services.borgbackup.jobs.box-backup.exclude = [
      config.services.loki.configuration.storage_config.filesystem.directory
    ];

    services.promtail = {
      enable = true;
      configuration = {

        server = {
          http_listen_port = 28183;
          grpc_listen_port = 0;
        };

        positions = { filename = "/tmp/positions.yml"; };

        clients = [{
          url = "http://localhost:${toString port-loki}/loki/api/v1/push";
        }];

        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "${config.networking.hostName}";
            };
          };
          relabel_configs = [{

            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
      };
    };
  };
}
