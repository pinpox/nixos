{
  pkgs,
  ...
}:
{

  imports = [
    ./disko-config-btrfs.nix
    # nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  hardware = {
    # fw-fanctrl.enable = true;
    # amdgpu.opencl.enable = true;
    xone.enable = true;
  };

  networking.hostName = "mango";

  # Strix Halo unified-memory tuning: IOMMU off + 124 GiB GTT/TTM ceiling.
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=126976"
    "ttm.pages_limit=32505856"
  ];

  home-manager.users.pinpox.pinpox.programs.games.enable = true;

  programs = {

    # Games
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    gamemode = {
      enable = true;
      settings.custom = {
        # Keep the screen awake while gaming.
        start = "${pkgs.systemd}/bin/systemd-run --user --unit=gaming-wlinhibit --collect ${pkgs.wlinhibit}/bin/wlinhibit";
        end = "${pkgs.systemd}/bin/systemctl --user stop gaming-wlinhibit";
      };
    };
  };
}
