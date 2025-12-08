{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.sound;
in
{

  options.pinpox.defaults.sound = {
    enable = mkEnableOption "sound defaults";
  };
  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.qjackctl ];

    services.pipewire = {
      enable = true;

      # Use pipeware to emulate jack and pulseaudio
      jack.enable = true;
      pulse.enable = true;
      alsa.enable = true;

      configPackages =

        let
          rnnoiseFilter = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";
                control = {
                  "VAD Threshold (%)" = 75.0;
                  "VAD Grace Period (ms)" = 200;
                  "Retroactive VAD Grace (ms)" = 100;
                };
              }
            ];
          };

          mkFilterChain =
            {
              name,
              capture,
              playback,
            }:
            {
              name = "libpipewire-module-filter-chain";

              args = {
                "node.description" = name;
                "media.name" = name;

                "filter.graph" = rnnoiseFilter;

                "capture.props" = {
                  "audio.rate" = 48000;
                }
                // capture;

                "playback.props" = {
                  "audio.rate" = 48000;
                }
                // playback;
              };
            };

          inputFilter = mkFilterChain {
            name = "Noise Cancelling Source";

            capture = {
              # > indicate that a link is passive and does not cause the graph to be runnable.
              # https://docs.pipewire.org/group__pw__keys.html#gafcd3d133168b9353c89c1c5f2de6954e
              "node.passive" = true;
              "node.name" = "capture.rnnoise_source";
            };
            playback = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
            };
          };

          outputFilter = mkFilterChain {
            name = "Noise Cancelling Sink";

            capture = {
              "node.name" = "capture.rnnoise_sink";
              "media.class" = "Audio/Sink";
            };
            playback = {
              "node.passive" = true;
              "node.name" = "rnnoise_sink";
              "media.class" = "Stream/Output/Audio";
            };
          };

          config = {
            "context.modules" = [
              inputFilter
              outputFilter
            ];
          };
        in
        [
          (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/99-input-denoising.conf" (
            builtins.toJSON config
          ))
        ];

    };

    # Use noisetorch (RNnoise) to create a virtual source with noise removal
    programs.noisetorch.enable = true;

    # services.pipewire.wireplumber.enable = true;

    # environment.etc."wireplumber/main.lua.d/90-suspend-timeout.lua" = {
    #   text = ''
    #     session.suspend-timeout-seconds = 0
    #   '';
    # };
  };
}
