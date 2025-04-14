{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.audio-recording;
  plugins = with pkgs; [
    # Instruments
    x42-avldrums
    zynaddsubfx

    # Effects
    calf
    lsp-plugins
    zam-plugins
    talentedhack
    gxplugins-lv2

    # TODO https://github.com/NixOS/nixpkgs/issues/348871
    # distrho
  ];
in
{

  # These settings yield 10ms@1024 spls latency in reaper for me:
  # pw-metadata -n settings 0 clock.force-quantum 1024
  # pw-metadata -n settings 0 clock.force-rate 96000

  options.pinpox.defaults.audio-recording.enable =
    mkEnableOption "audio production setup (DAW and plugins)";

  config = mkIf cfg.enable {

    home.packages =
      with pkgs;
      [
        reaper
        alsa-scarlett-gui
      ]

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
