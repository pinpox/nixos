{ config, lib, pkgs, ... }:

with lib;

let cfg = config.pinpox.programs.zed;

in {
  options.pinpox.programs.zed = {
    enable = mkEnableOption "Zed editor configuration";
  };

  config = mkIf cfg.enable {
    services.gnome-keyring.enable = true;
    
    # Add nixd (Nix language server) for better Nix support
    home.packages = with pkgs; [
      nixd
    ];
    
    programs.zed-editor = {
      enable = true;
      extensions = ["nix"];
      userSettings = {
        telemetry = {
          metrics = false;
          diagnostics = false;
        };
        vim_mode = true;
        ui_font_size = 15;
        buffer_font_size = 15;
        buffer_font_family = "Berkeley Mono";
        ui_font_family = "Berkeley Mono";
        theme = {
          mode = "dark";
          light = "Ayu Light";
          dark = "One Dark";
        };
        language_overrides = {
          nix = {
            language_server_id = "nixd";
          };
        };
      };
    };
  };
}