{

  restic-exporter,
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.server;
in
{

  imports = [
    ../../users/pinpox.nix
    restic-exporter.nixosModules.default
  ];

  options.pinpox.server = {
    enable = mkEnableOption "the default server configuration";

    stateVersion = mkOption {
      type = types.str;
      default = "20.03";
      example = "21.09";
      description = "NixOS state-Version";
    };
  };

  config = mkIf cfg.enable {

    hardware.enableRedistributableFirmware = true;

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
    pinpox.services = {
      openssh.enable = true;
    };

    # Backups
    pinpox.services = {
      restic-client = {
        enable = true;
        backup-paths-exclude = [
          "*.pyc"
          "*/.cache"
          "*/.cargo"
          "*/.container-diff"
          "*/.go/pkg"
          "*/.gvfs/"
          "*/.local/share/Steam"
          "*/.local/share/Trash"
          "*/.local/share/virtualenv"
          "*/.mozilla/firefox"
          "*/.rustup"
          "*/.vim"
          "*/.vimtemp"
        ];
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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = cfg.stateVersion; # Did you read the comment?
  };
}
