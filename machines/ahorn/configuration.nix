# Configuration file for ahorn
{ self, ... }:
{ pkgs, ... }: {

  imports = [ ./hardware-configuration.nix ./retiolum.nix ];

  networking.retiolum.ipv4 = "10.243.100.100";
  networking.retiolum.ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "/var/src/secrets/retiolum/rsa_priv";
    ed25519PrivateKeyFile = "/var/src/secrets/retiolum/ed25519_priv";
  };
  # services.vault.enable = true;
  # services.vault.extraConfig = ''
  # ui = true
  # '';

  # services.vault.package = pkgs.vault-bin;

  services.telegraf = {
    enable = true;
    extraConfig = {
      agent.interval = "60s";
      inputs = {

        #        #syslog.server = "unixgram:///run/systemd/journal/syslog";
        #        #syslog.best_effort = true;
        #        #syslog.syslog_standard = "RFC3164";
        #        prometheus.urls = lib.mkIf (config.services.promtail.enable) [
        #          # default promtail port
        #          "http://localhost:9080/metrics"
        #        ];
        #        prometheus.metric_version = 2;
        #        smart = lib.mkIf (!isVM) {
        #          path = pkgs.writeShellScript "smartctl" ''
        #            exec /run/wrappers/bin/sudo ${pkgs.smartmontools}/bin/smartctl "$@"
        #          '';
        #        };
        #        file = [{
        #          data_format = "influx";
        #          file_tag = "name";
        #          files = [ "/var/log/telegraf/*" ];
        #        }] ++ lib.optional (lib.any (fs: fs == "ext4") config.boot.supportedFilesystems) {
        #          name_override = "ext4_errors";
        #          files = [ "/sys/fs/ext4/*/errors_count" ];
        #          data_format = "value";
        #        };
        #        disk.tagdrop = {
        #          fstype = [ "tmpfs" "ramfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" ];
        #          device = [ "rpc_pipefs" "lxcfs" "nsfs" "borgfs" ];
        #        };

        mdstat = { };
        system = { };
        mem = { };
        kernel_vmstat = { };
        systemd_units = { };
        swap = { };
        diskio = { };
      };
      outputs = {

        prometheus_client = {
          listen = ":9273";
          metric_version = 2;
        };
      };

    };

  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };

  # TODO remove when no longer needed
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
