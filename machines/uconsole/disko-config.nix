{ pkgs, config, lib, ... }:
let
  # Raspberry Pi firmware files needed for boot
  rpiFirmware = pkgs.raspberrypifw;

  # Get the kernel and initrd from the NixOS system being built
  toplevel = config.system.build.toplevel;

  # Get the kernel package for DTB overlays
  kernelPackage = config.boot.kernelPackages.kernel;

  # config.txt for Raspberry Pi CM4 / uConsole
  # IMPORTANT: Kernel must be at root level, not in subdirectory - GPU firmware can't load from subdirs
  configTxt = pkgs.writeText "config.txt" ''
    [all]
    arm_64bit=1
    enable_uart=1
    uart_2ndstage=1
    avoid_warnings=1
    disable_overscan=1
    disable_splash=0

    # GPU memory allocation (256MB for GPU)
    gpu_mem=256

    # Ignore LCD detect - we use DSI display
    ignore_lcd=1

    # Audio settings
    disable_audio_dither=1
    pwm_sample_bits=20

    # Device tree debug (use vclog -m to view)
    dtdebug=1

    # GPIO configuration for uConsole hardware
    gpio=10=ip,np
    gpio=11=op,dh

    # Enable VC4 graphics driver - MUST use pi4 variant for CM4
    # cma-384 allocates 384MB contiguous memory for GPU (needed for full resolution)
    dtoverlay=vc4-kms-v3d-pi4,cma-384

    # USB controller - host mode
    dtoverlay=dwc2,dr_mode=host

    # uConsole display and hardware overlay
    dtoverlay=clockworkpi-uconsole

    # Audio routing to GPIO 12/13 (headphone jack)
    dtoverlay=audremap,pins_12_13

    # External WiFi antenna
    dtparam=ant2=on
    dtparam=audio=on

    # Kernel and initrd at root level (GPU firmware can't load from subdirectories)
    kernel=kernel.img
    initramfs initrd.img followkernel

    # Device tree for CM4
    device_tree=bcm2711-rpi-cm4.dtb

    [cm4]
    # CM4-specific settings
    otg_mode=0
    over_voltage=6
    arm_freq=2000
    gpu_freq=750
    force_turbo=1
    dtparam=spi=on
  '';

  # cmdline.txt for kernel parameters
  cmdlineTxt = pkgs.writeText "cmdline.txt" ''
    console=tty1 root=LABEL=NIXOS_SD rootfstype=btrfs rootflags=subvol=/root init=${toplevel}/init loglevel=4 fbcon=rotate:1 video=DSI-1:panel_orientation=right_side_up
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
    ${pkgs.mtools}/bin/mmd -i "$out/main.raw"@@$OFFSET ::overlays || true

    # Copy Raspberry Pi firmware
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/start4.elf ::
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/fixup4.dat ::
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${rpiFirmware}/share/raspberrypi/boot/bootcode.bin :: || true

    # Copy kernel and initrd to ROOT level (GPU firmware can't load from subdirectories!)
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${toplevel}/kernel ::kernel.img
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${toplevel}/initrd ::initrd.img

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
    ${pkgs.mtools}/bin/mcopy -i "$out/main.raw"@@$OFFSET ${cmdlineTxt} ::cmdline.txt

    # List what we copied
    ${pkgs.coreutils}/bin/echo "=== Firmware partition contents ==="
    ${pkgs.mtools}/bin/mdir -i "$out/main.raw"@@$OFFSET ::

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
            # Root partition with BTRFS
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
