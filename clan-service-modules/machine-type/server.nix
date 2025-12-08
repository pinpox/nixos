{
  restic-exporter,
  lib,
  pkgs,
  config,
  ...
}:
with lib;
{

  imports = [
    restic-exporter.nixosModules.default
  ];

  # Limit log size for journal
  services.journald.extraConfig = "SystemMaxUse=1G";

  environment.systemPackages = with pkgs; [
    universal-ctags
    git
    gnumake
    go
    htop
    neovim
    nix-index
    nixfmt-rfc-style
    ripgrep
    wget
    ncdu
    duf
    tmux
  ];

  pinpox.defaults = {
    environment.enable = true;
    locale.enable = true;
    nix.enable = true;
    zsh.enable = true;
    networking.enable = true;
  };

  pinpox.services.openssh.enable = true;

  # Backups
  pinpox.services = {
    restic-client = {
      enable = true;
      backup-paths-onsite = [
        config.services.postgresqlBackup.location
        "/home"
        "/root"
      ];
    };
  };

  # Backup Postgres, if it is running
  services.postgresqlBackup = {
    enable = config.services.postgresql.enable;
    startAt = "*-*-* 01:15:00";
    location = "/var/backup/postgresql";
    backupAll = true;
  };

  # Remove wayland dependencies on server machine type
  nixpkgs.overlays = [

    (final: super: {
      passage = super.passage.override {
        wl-clipboard = null;
        xclip = null;
      };

      neovim = super.neovim.override {
        waylandSupport = false;
      };
    })
  ];
}
