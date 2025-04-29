{ lib, config, ... }:
{

  # You may also find this setting useful to automatically set the latest compatible kernel:
  boot.kernelPackages = lib.mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems.zfs = true;

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 4; # 15 min
    hourly = 24;
    daily = 7;
    weekly = 4;
    monthly = 0;
  };

  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "nofail" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              #keylocation = "file:///tmp/secret.key";
              keylocation = "prompt";
            };
            mountpoint = "/";
          };

          "root/nix" = {
            type = "zfs_fs";
            options.mountpoint = "/nix";
            mountpoint = "/nix";
          };

          "root/home" = {
            type = "zfs_fs";
            options.mountpoint = "/home";
            mountpoint = "/home";
          };

          "root/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "/var/lib";
            mountpoint = "/var/lib";
          };

          # "root/tmp" = {
          #   type = "zfs_fs";
          #   mountpoint = "/tmp";
          #   options = {
          #     mountpoint = "/tmp";
          #     sync = "disabled";
          #   };
          # };

          # README MORE: https://wiki.archlinux.org/title/ZFS#Swap_volume
          # "root/swap" = {
          #   type = "zfs_volume";
          #   size = "10M";
          #   content = {
          #     type = "swap";
          #   };
          #   options = {
          #     volblocksize = "4096";
          #     compression = "zle";
          #     logbias = "throughput";
          #     sync = "always";
          #     primarycache = "metadata";
          #     secondarycache = "none";
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
        };
      };
    };
  };
}
