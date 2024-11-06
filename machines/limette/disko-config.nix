{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vdb";
        # device = builtins.elemAt disks 0;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "BOOT";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
                extraArgs = [
                  "-n"
                  "BOOT"
                ];
              };
            };
            luks = {
              size = "100%";
              name = "SYSTEM";
              content = {
                type = "luks";
                name = "root";
                extraOpenArgs = [ ];
                passwordFile = "/tmp/secret.key";
                settings.allowDiscards = true;
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
                extraFormatArgs = [
                  "--label LUKS"
                ];
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          swap = {
            name = "swap";
            size = "8G";
            content = {
              type = "swap";
              resumeDevice = true;
              extraArgs = [ "-L swap" ];
            };
          };
          root = {
            name = "root";
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
              extraArgs = [ "-L root" ];
            };
          };
        };
      };
    };
  };
}
