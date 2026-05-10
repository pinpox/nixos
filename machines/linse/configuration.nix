{
  nixos-hardware,
  lib,
  ...
}:
{

  imports = [
    ./disko-config.nix
    nixos-hardware.nixosModules.gpd-win-2
  ];

  clan.core.networking.targetHost = "192.168.101.158";
  networking.hostName = "linse";

  # GPD Win 2's keyboard is plain QWERTY — no colemak.
  console.keyMap = lib.mkForce "us";

  # Animated wallpaper is too heavy for the m3-7y30 / HD 615 — don't auto-start.
  home-manager.users.pinpox.systemd.user.services.wl-harmonograph.Install.WantedBy = lib.mkForce [ ];

  # GPD Win 2 shoulder buttons (in mouse mode) emit numpad-1/numpad-2.
  # Bind by scancode, scoped to the gamepad's keyboard device, so external
  # numpads on other keyboards aren't affected.
  home-manager.users.pinpox.wayland.windowManager.sway.extraConfig = ''
    bindcode --input-device='121:6358:Mouse_for_Windows' 83 workspace prev
    bindcode --input-device='121:6358:Mouse_for_Windows' 89 workspace next
  '';

  # Original install used systemd-boot; the GPD's firmware boots that and
  # ignores GRUB's BOOTX64.EFI fallback. Stick with systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  pinpox.defaults.lvm-grub.enable = lib.mkForce false;

  # GPD Win 2's SDHCI controller wedges on driver cleanup, blocking shutdown.
  # Boot/storage is on SATA, so disabling the SD reader is safe. Re-enable
  # (delete the line below) when you actually want to use the microSD slot.
  boot.blacklistedKernelModules = [ "sdhci_pci" ];

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
  ];
}
