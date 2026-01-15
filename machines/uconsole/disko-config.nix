{
  # Auto-resize root partition on first boot to fill the SD card
  boot.growPartition = true;
  boot.supportedFilesystems.btrfs = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Image size for generation (actual SD card will be larger)
        imageSize = "8G";
        content = {
          type = "gpt";
          partitions = {
            # FAT32 firmware partition for Raspberry Pi bootloader
            # Pi bootloader reads kernel, initrd, device tree from here
            firmware = {
              size = "512M";
              label = "FIRMWARE";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };
            # LUKS-encrypted root with BTRFS
            luks = {
              size = "100%";
              label = "NIXOS_SD";
              content = {
                type = "luks";
                name = "crypted";
                # Interactive password entry at boot
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "1G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
