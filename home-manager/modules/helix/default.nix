{ config, lib, pkgs, ... }:

with lib;

let cfg = config.pinpox.programs.helix;

in {
  options.pinpox.programs.helix = {
    enable = mkEnableOption "Helix editor configuration";
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;

      # https://docs.helix-editor.com/languages.html
      languages = {
        language = [
          {
            name = "nix";
            auto-format = false;
            formatter.command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
          }
        ];
      };

      settings = {
        editor = {
          indent-guides.render = true;
          bufferline = "multiple";
          cursorline = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          lsp.display-messages = true;
        };

        theme = "catppuccin_mocha";

        keys = {
          normal = {
            ";" = "command_mode";
            "C-g" = [
              ":new"
              ":insert-output ${pkgs.lazygit}/bin/lazygit"
              ":buffer-close!"
              ":redraw"
            ];
          };
          select = {
            ";" = "command_mode";
          };
        };
      };
    };

    # Add helix to home packages
    home.packages = with pkgs; [
      helix
    ];
  };
}