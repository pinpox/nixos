{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
# Push-to-talk shopping list: the kitchen Atom (kitchen-atom.yaml) streams one
# button press of audio, the bridge transcribes it and hands the text to the
# "kitchen" opencrow bot (inventory/opencrow.nix) through its trigger pipe. The
# bot keeps the list with the shopping-list skill.
#
# Kitchen timers: the bot writes one file per timer into its timers directory
# (kitchen-timer skill), the bridge rings the Atom and tells the bot when one
# runs out.
let
  cfg = config.pinpox.services.kitchen-dictation;

  # State dir of the "kitchen" opencrow instance on the same machine.
  stateDir = "/var/lib/opencrow-kitchen";
  pipe = "${stateDir}/sessions/trigger.pipe";
  # Created inside the container (inventory/opencrow.nix), owned by the bot.
  timers = "${stateDir}/timers";

  bridge = pkgs.writers.writePython3Bin "kitchen-dictation" {
    libraries = with pkgs.python3Packages; [
      aioesphomeapi
      faster-whisper
      numpy
    ];
  } (builtins.readFile ./bridge.py);
in
{
  options.pinpox.services.kitchen-dictation = {
    enable = mkEnableOption "push-to-talk dictation from the kitchen Atom into opencrow";
    device = mkOption {
      type = types.str;
      example = "192.168.101.130";
      description = "Address of the Atom's ESPHome API on the machine's LAN.";
    };
  };

  config = mkIf cfg.enable {

    # The Atom's ESPHome API key. Flash it into the Atom's secrets.yaml as
    # api_key: `clan vars get <machine> kitchen-dictation/api-key`.
    clan.core.vars.generators.kitchen-dictation = {
      files.api-key = { };
      runtimeInputs = [
        pkgs.coreutils
        pkgs.openssl
      ];
      script = ''
        openssl rand -base64 32 | tr -d '\n' > $out/api-key
      '';
    };

    # The Atom's ESPHome OTA password, the secrets.yaml ota_password. Only
    # stored here for the next flash, never deployed:
    # `clan vars get <machine> kitchen-atom/ota-password`.
    clan.core.vars.generators.kitchen-atom = {
      prompts.ota-password = {
        type = "hidden";
        persist = true;
        description = "OTA password flashed into the kitchen Atom";
      };
      files.ota-password.deploy = false;
    };

    systemd.services.kitchen-dictation = {
      description = "Push-to-talk dictation from the kitchen Atom into opencrow";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        DEVICE = cfg.device;
        PIPE = pipe;
        TIMERS = timers;
        # base and tiny mishear German food words.
        MODEL = "small";
        HF_HOME = "/var/cache/kitchen-dictation";
      };
      # Root: the pipe and the timers belong to the container's opencrow
      # user, which does not exist on the host.
      serviceConfig = {
        ExecStart = getExe bridge;
        LoadCredential = "api-key:${config.clan.core.vars.generators.kitchen-dictation.files.api-key.path}";
        CacheDirectory = "kitchen-dictation";
        Restart = "always";
        RestartSec = "10s";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        # The whole state dir: the timers dir may only appear once the
        # container is up, after the bridge started.
        ReadWritePaths = [ stateDir ];
      };
    };
  };
}
