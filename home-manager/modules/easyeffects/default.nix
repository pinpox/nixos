{ config, lib, pkgs, ... }:

with lib;

let cfg = config.pinpox.programs.easyeffects;

in {
  options.pinpox.programs.easyeffects = {
    enable = mkEnableOption "EasyEffects audio effects";
  };

  config = mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      # preset = "my-preset";
      # extraPresets = {
      #   my-preset = {
      #     input = {
      #       blocklist = [
      #
      #       ];
      #       "plugins_order" = [
      #         "rnnoise#0"
      #       ];
      #       "rnnoise#0" = {
      #         bypass = false;
      #         "enable-vad" = false;
      #         "input-gain" = 0.0;
      #         "model-path" = "";
      #         "output-gain" = 0.0;
      #         release = 20.0;
      #         "vad-thres" = 50.0;
      #         wet = 0.0;
      #       };
      #     };
      #   };
      # };
    };

    # Add easyeffects to home packages
    home.packages = with pkgs; [
      easyeffects
    ];
  };
}
