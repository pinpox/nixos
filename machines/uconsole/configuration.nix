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

  # ============================================================================
  # EARLY DISPLAY MODULES FOR INITRAMFS
  # ============================================================================
  # Goal: Get the uConsole's built-in screen working as early as possible
  # during boot, so we can later see the LUKS password prompt.
  #
  # Based on:
  # - https://blog.quendi.moe/2024/07/25/en-enabling-fde-on-the-clockworkpi-uconsole/
  # - https://forum.clockworkpi.com/t/updated-guide-for-bookworm-encrypted-root-partition-on-uconsole/15778/4
  #   (fenryxo's solution for initramfs display)
  #
  # The 18-second delay before screen activates is caused by late I2C bus
  # initialization, which delays the AXP228 power management IC that controls
  # the display power rail.
  # ============================================================================

  boot.initrd.kernelModules = [
    # DRM core and helpers - needed for framebuffer console
    "drm"
    "drm_kms_helper"
    "drm_display_helper"
    "drm_dma_helper"
    "drm_shmem_helper"
    "drm_panel_orientation_quirks"
    "ttm"
    # Note: drm_ttm_helper may be built-in or merged into ttm

    # GPU drivers for BCM2711 (CM4)
    "v3d"       # Broadcom V3D 3D graphics
    "vc4"       # Broadcom VC4 graphics (includes DSI support)

    # Panel and backlight drivers (uConsole specific)
    "panel_cwu50"   # CWU50 5" DSI panel driver
    "ocp8178_bl"    # OCP8178 backlight controller (1-wire GPIO)
    "backlight"     # Backlight subsystem
    "pwm_bcm2835"   # PWM driver for backlight

    # I2C bus drivers - CRITICAL for early display!
    # i2c_bcm2708 is the BSC controller driver for fe205000.i2c where AXP228 lives
    # Without this loaded early, display power doesn't come up until ~9s into boot.
    "i2c_bcm2708"   # THIS IS THE KEY ONE - drives the bus with AXP228
    "i2c_brcmstb"
    "i2c_bcm2835"
    "i2c_dev"
    "i2c_mux"
    "i2c_mux_pinctrl"

    # Power management - AXP228 PMIC
    # Note: axp20x core and regulator may be built-in (=y) in RPi kernel
    # These are the loadable helper modules
    "axp20x_battery"
    "axp20x_ac_power"
    "axp20x_adc"
  ];

  # Console configuration for boot
  boot.kernelParams = [
    "console=tty1"
    "fbcon=rotate:1"  # uConsole display is rotated 90 degrees
    "fbcon=nodefer"   # Disable deferred framebuffer console takeover
    "loglevel=4"
    # Force DSI panel orientation
    "video=DSI-1:panel_orientation=right_side_up"
  ];

  # Additional modules available in initrd (not forced to load)
  boot.initrd.availableKernelModules = [
    # USB ethernet adapters (for network debugging)
    "usbnet"
    "ax88179_178a"
    "cdc_ether"
    "r8152"
  ];

  # Enable Mesa GPU drivers for Wayland/graphics support
  hardware.graphics.enable = true;
  # 32-bit graphics not supported on aarch64
  hardware.graphics.enable32Bit = lib.mkForce false;

  # Console font sized for the 5" 720x1280 display
  # earlySetup ensures the font is available in initramfs
  console = {
    earlySetup = true;
    font = "ter-v24n";
    packages = with pkgs; [ terminus_font ];
  };

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
