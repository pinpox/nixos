# ---
# schema = "btrfs-single-disk-subvolumes"
# [placeholders]
# mainDisk = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_1TB_S467NX0MB03860Y" 
# ---
# This file was automatically generated!
# CHANGING this configuration requires wiping and reinstalling the machine
{
  boot.loader.grub = {
    efiInstallAsRemovable = true;
    efiSupport = true;
  };

  disko.devices = {
    disk = {
      "main" = {
        name = "main-9bea948ae69a4a528dcdabbe9fe39bfb";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_1TB_S467NX0MB03860Y";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            "ESP" = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            #"swap" = {
            #  size = "8G"; # adjust
            #  content = {
            #    type = "swap";
            #    discardPolicy = "both";
            #  };
            #};
            "root" = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "--force"
                  "--label root"
                ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Automatic local snapshots
  # https://digint.ch/btrbk/doc/readme.html
  #$ systemctl start btrbk-<instance>
  services.btrbk = {
    instances."nix" = {
      onCalendar = "*/2:00";
      settings = {
        subvolume = "/nix";
        snapshot_create = "onchange";
        snapshot_dir = "/nix";
        snapshot_preserve = "16h 7d 2w";
        snapshot_preserve_min = "3d";
      };
    };
    instances."home" = {
      onCalendar = "*/2:00";
      settings = {
        subvolume = "/home";
        snapshot_dir = "/home";
        snapshot_preserve = "16h 7d 3w 2m";
        snapshot_preserve_min = "3d";
      };
    };
  };
}
