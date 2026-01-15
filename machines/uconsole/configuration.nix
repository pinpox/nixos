{
  nixos-hardware,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.clockworkpi-uconsole-cm4
    ./disko-config.nix
  ];

  # uConsole uses a Raspberry Pi CM4 (aarch64)
  nixpkgs.hostPlatform = "aarch64-linux";

  networking.hostName = "uconsole";

  # Disable grub - we use extlinux from the rpi4 module
  boot.loader.grub.enable = lib.mkForce false;

  # Additional initrd modules for early display (LUKS prompt)
  boot.initrd.kernelModules = [
    "drm"
    "drm_kms_helper"
    "vc4"
    "panel_cwu50"
    "ocp8178_bl"
    "pwm_bcm2835"
    "i2c_bcm2835"
    "i2c_dev"
  ];

  # Console configuration and root device for boot
  boot.kernelParams = [
    "console=tty1"
    "fbcon=rotate:1"  # uConsole display is rotated 90 degrees
    "root=LABEL=NIXOS_SD"
    "rootfstype=btrfs"
    "rootflags=subvol=/root"
    # Maximum debug logging
    "loglevel=7"
    "initcall_debug"
    "printk.devkmsg=on"
    # Panic/crash logging
    "panic=30"  # Reboot after 30s on panic
    # Raspberry Pi console
    "earlycon"
    # Ramoops for preserving kernel logs across crashes
    "ramoops.mem_address=0x3df00000"
    "ramoops.mem_size=0x100000"
    "ramoops.ecc=1"
  ];

  # Add modules needed in initrd
  boot.initrd.availableKernelModules = [
    # USB ethernet adapters
    "usbnet"
    "ax88179_178a"
    "cdc_ether"
    "r8152"
    # FAT32 for firmware partition logging
    "vfat"
    "nls_cp437"
    "nls_iso8859-1"
    # Crash logging
    "ramoops"
    "pstore"
  ];

  # Enable emergency access for debugging
  boot.initrd.systemd.emergencyAccess = true;

  # Absolute earliest marker - runs immediately when systemd starts
  boot.initrd.systemd.services.boot-marker = {
    description = "Write boot marker to firmware partition";
    wantedBy = [ "sysinit.target" ];
    before = [ "sysinit.target" ];
    unitConfig = {
      DefaultDependencies = false;
      RequiresMountsFor = "";  # No mount requirements
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "boot-marker" ''
        # Try repeatedly for 5 seconds to write marker
        for i in 1 2 3 4 5 6 7 8 9 10; do
          if [ -b /dev/mmcblk0p1 ]; then
            mkdir -p /mnt-marker
            if mount -t vfat /dev/mmcblk0p1 /mnt-marker 2>/dev/null; then
              echo "INITRD_STARTED $(cat /proc/uptime)" > /mnt-marker/boot-marker.txt
              sync
              umount /mnt-marker
              exit 0
            fi
          fi
          sleep 0.5
        done
      '';
    };
  };

  # Write boot logs to firmware partition for debugging (systemd initrd)
  # This service runs as early as possible
  boot.initrd.systemd.services.boot-logger = {
    description = "Write boot logs to firmware partition";
    wantedBy = [ "sysinit.target" ];  # Run very early
    after = [ "systemd-udevd.service" ];  # Just need udev for device nodes
    before = [ "sysinit.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "boot-logger" ''
        echo "=== Boot logger starting ===" > /dev/kmsg
        mkdir -p /mnt-boot-log

        # Try to mount firmware partition
        if mount -t vfat /dev/mmcblk0p1 /mnt-boot-log 2>/dev/null; then
          {
            echo "=== NixOS Boot Log ==="
            echo "Date: $(date 2>/dev/null || echo 'unknown')"
            echo ""
            echo "=== Kernel messages (dmesg) ==="
            dmesg 2>/dev/null || cat /dev/kmsg 2>/dev/null || echo "dmesg unavailable"
            echo ""
            echo "=== Block devices ==="
            ls -la /dev/mmcblk* /dev/sd* /dev/disk/by-label/* 2>&1 || true
            echo ""
            echo "=== Loaded modules ==="
            cat /proc/modules 2>/dev/null || echo "modules unavailable"
            echo ""
            echo "=== Mount points ==="
            mount 2>/dev/null || echo "mount unavailable"
          } > /mnt-boot-log/boot.log
          sync
          umount /mnt-boot-log
          echo "Boot log written to /dev/mmcblk0p1/boot.log" > /dev/kmsg
        else
          echo "Failed to mount firmware partition for logging" > /dev/kmsg
        fi
      '';
    };
  };

  # Also log after root is mounted
  boot.initrd.systemd.services.boot-logger-post = {
    description = "Write post-mount boot logs";
    wantedBy = [ "initrd.target" ];
    after = [ "initrd-root-fs.target" "sysroot.mount" ];
    before = [ "initrd-parse-etc.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "boot-logger-post" ''
        mkdir -p /mnt-boot-log
        if mount -t vfat /dev/mmcblk0p1 /mnt-boot-log 2>/dev/null; then
          {
            echo ""
            echo "=== POST-MOUNT LOG ==="
            echo "Date: $(date 2>/dev/null || echo 'unknown')"
            echo "Root filesystem mounted successfully!"
            echo ""
            echo "=== Current mounts ==="
            mount
            echo ""
            echo "=== Latest dmesg ==="
            dmesg | tail -100
          } >> /mnt-boot-log/boot.log
          sync
          umount /mnt-boot-log
        fi
      '';
    };
  };

  # 32-bit graphics not supported on aarch64
  hardware.graphics.enable32Bit = lib.mkForce false;

  # Filesystems are now managed by disko (see disko-config.nix)

  # Enable NetworkManager for easy WiFi setup
  networking.networkmanager.enable = true;

  # Pre-configure WiFi for debugging (password in plain text - change later)
  networking.networkmanager.ensureProfiles.profiles = {
    "virus.exe" = {
      connection = {
        id = "virus.exe";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        ssid = "virus.exe";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "gerolsteiner";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        method = "auto";
      };
    };
  };

  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Set initial root password for debugging (change after first login!)
  users.users.root.initialPassword = "nixos";
}
