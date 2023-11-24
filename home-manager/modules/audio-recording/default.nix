{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.pinpox.defaults.audio-recording;
in
{

  options.pinpox.defaults.audio-recording.enable = mkEnableOption "audio production setup (DAW and plugins)";

  config =
    let

      plugins = with pkgs; [
        # Instruments
        x42-avldrums
        zynaddsubfx

        # Effects
        calf
        lsp-plugins
        distrho
        zam-plugins
        talentedhack
        gxplugins-lv2
      ];

    in
    mkIf cfg.enable {

      home.packages = with pkgs; [ reaper ]

        # Some plugins also have a binary, so we also add them to PATH
        ++ plugins;

      # Place vst, vst3, clap, lv2 and ladspa plugins in the according
      # directories where reaper will look for them
      home.file =
        let
          all-audio-plugins = pkgs.symlinkJoin {
            name = "all-audio-plugins";
            paths = plugins;
          };
        in
        {

          all-lv2 = {
            recursive = true;
            source = "${all-audio-plugins}/lib/lv2";
            target = ".lv2";
          };

          all-clap = {
            recursive = true;
            source = "${all-audio-plugins}/lib/clap";
            target = ".clap";
          };

          all-vst = {
            recursive = true;
            source = "${all-audio-plugins}/lib/vst";
            target = ".vst";
          };

          all-vst3 = {
            recursive = true;
            source = "${all-audio-plugins}/lib/vst3";
            target = ".vst3";
          };

          all-ladspa = {
            recursive = true;
            source = "${all-audio-plugins}/lib/ladspa";
            target = ".ladspa";
          };
        };
    };
}
