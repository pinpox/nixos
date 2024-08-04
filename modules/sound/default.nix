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

    # Use pipeware to emulate jack and pulseaudio
    services.pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;
      alsa.enable = true;

      configPackages = [
        (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/99-input-denoising.conf" ''
          context.modules = [
            { name = libpipewire-module-filter-chain
              args = {
                node.description = "Noise Cancelling Source"
                media.name = "Noise Cancelling Source"
                filter.graph = {
                  nodes = [
                    {
                      type = ladspa
                      name = rnnoise
                      plugin = ${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so
                      label = noise_suppressor_mono
                      control = {
                        "VAD Threshold (%)" = 75.0
                        "VAD Grace Period (ms)" = 200
                        "Retroactive VAD Grace (ms)" = 100
                      }
                    }
                  ]
                }
                capture.props = {
                  node.name = "capture.rnnoise_source"
                  node.passive = true
                  audio.rate = 48000
                }
                playback.props = {
                  node.name = "rnnoise_source"
                  media.class = Audio/Source
                  audio.rate = 48000
                }
              }
            }
          ]
        '')
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
