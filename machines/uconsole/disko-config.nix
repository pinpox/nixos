{ pkgs, config, lib, ... }:
let
  # Raspberry Pi firmware files needed for boot
  rpiFirmware = pkgs.raspberrypifw;

  # Get the kernel and initrd from the NixOS system being built
  toplevel = config.system.build.toplevel;

  # Get the kernel package for DTB overlays
  kernelPackage = config.boot.kernelPackages.kernel;

  # config.txt for Raspberry Pi CM4 / uConsole
  configTxt = pkgs.writeText "config.txt" ''
    [all]
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
    disable_overscan=1
    disable_splash=0

    # HDMI output configuration
    hdmi_force_hotplug=1
    hdmi_drive=2
    config_hdmi_boost=4

    # Enable VC4 graphics driver for HDMI output
    dtoverlay=vc4-kms-v3d

    # Use kernel and initrd from extlinux
    kernel=nixos/default-kernel
    initramfs nixos/default-initrd followkernel

    # Device tree for CM4
    device_tree=bcm2711-rpi-cm4.dtb

    # uConsole display and hardware overlay
    dtoverlay=clockworkpi-uconsole

    [cm4]
    # CM4-specific settings
    otg_mode=1
  '';

  # extlinux.conf for boot menu
  extlinuxConf = pkgs.writeText "extlinux.conf" ''
    TIMEOUT 30
    DEFAULT nixos
    MENU TITLE NixOS Boot Menu

    LABEL nixos
      MENU LABEL NixOS
      LINUX ../nixos/default-kernel
      INITRD ../nixos/default-initrd
      FDTDIR ../
      APPEND init=${toplevel}/init root=LABEL=NIXOS_SD rootfstype=btrfs rootflags=subvol=/root loglevel=7 console=tty1 fbcon=rotate:1
  '';

in
{
  # Use a generic kernel for the disko VM (the RPi CM4 kernel doesn't work in QEMU)
  disko.imageBuilder.kernelPackages = pkgs.linuxPackages;

  # Populate firmware partition after VM creates the base image
  # Note: Images are in $out after VM completes
  # We use mtools to write to the FAT partition without needing loop devices (sandbox-safe)
  disko.imageBuilder.extraPostVM = ''
    ${pkgs.coreutils}/bin/echo "=== Populating firmware partition ==="
    ${pkgs.coreutils}/bin/echo "Output directory: $out"
    ${pkgs.coreutils}/bin/ls -la "$out"

    # The firmware partition starts at 1MB (sector 2048) in GPT
    # mtools can access FAT filesystems with an offset
    export MTOOLS_SKIP_CHECK=1

    # Create mtools config to access the FAT partition at offset
    # Partition 1 starts at sector 2048 (offset 1048576 bytes)
    ${pkgs.coreutils}/bin/cat > /tmp/mtoolsrc << 'MTOOLSRC'
    drive c:
      file="$out/main.raw"
      partition=1
    MTOOLSRC
    export MTOOLSRC=/tmp/mtoolsrc

    # Actually, mtools partition support is tricky. Let's use a simpler approach:
    # Extract the partition offset using sfdisk and create a direct access config

    # Get partition info
    PART_INFO=$(${pkgs.util-linux}/bin/sfdisk -J "$out/main.raw")
    ${pkgs.coreutils}/bin/echo "Partition info: $PART_INFO"

    # First partition starts at sector 2048 (1MB) typically for GPT with 512M firmware
    # Offset = 2048 * 512 = 1048576 bytes
    OFFSET=1048576

    # Create mtools drive config with explicit offset
    ${pkgs.coreutils}/bin/cat > /tmp/mtoolsrc << EOF
    drive c: file="$out/main.raw" offset=$OFFSET
    EOF
    export MTOOLSRC=/tmp/mtoolsrc

    ${pkgs.coreutils}/bin/echo "=== Copying firmware files ==="

    # Create directories first
    ${pkgs.mtools}/bin/mmd -i "$out/main.raw"@@$OFFSET ::nixos || true
    ${pkgs.mtools}/bin/mmd -i "$out/main.raw"@@$OFFSET ::overlays || true
    ${pkgs.mtools}/bin/mmd -i "$out/main.raw"@@$OFFSET ::extlinux || true

    # Copy Raspberry Pi firmware
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/start4.elf ::
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/fixup4.dat ::
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/bootcode.bin :: || true

    # Copy kernel and initrd
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${toplevel}/kernel ::nixos/default-kernel
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${toplevel}/initrd ::nixos/default-initrd

    # Copy device tree for CM4 (from toplevel/dtbs/broadcom/)
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${toplevel}/dtbs/broadcom/bcm2711-rpi-cm4.dtb ::

    # Copy device tree overlays from kernel package
    for overlay in ${kernelPackage}/dtbs/overlays/*.dtbo; do
      if [ -f "$overlay" ]; then
        ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET "$overlay" ::overlays/ || true
      fi
    done

    # Copy config files
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${configTxt} ::config.txt
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${extlinuxConf} ::extlinux/extlinux.conf

    # List what we copied
    ${pkgs.coreutils}/bin/echo "=== Firmware partition contents ==="
    ${pkgs.mtools}/bin/mdir -i "$out/main.raw"@@$OFFSET ::
    ${pkgs.mtools}/bin/mdir -i "$out/main.raw"@@$OFFSET ::nixos
    ${pkgs.mtools}/bin/mdir -i "$out/main.raw"@@$OFFSET ::extlinux

    ${pkgs.coreutils}/bin/echo "=== Firmware population complete ==="
  '';


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
            # Firmware files are populated by extraPostVM after VM creates the image
            firmware = {
              size = "512M";
              type = "EF00";  # EFI System Partition type for GPT
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
            # Root partition with BTRFS (no LUKS for debugging)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-L" "NIXOS_SD" ];
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
}
