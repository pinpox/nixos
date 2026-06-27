# All opencrow bots + their Matrix/NATS keys. Auto-merged into inventory.nix's
# `instances`; the `matrix` and `nats` instances live there (keys merged in here).
{ self, ... }:
let
  # mango's llama-swap OpenAI API via its .pin name; apiKey is the env-var NAME
  # omp reads (from the shared pi-llama-swap-key env file).
  mangoPiModels.providers.mango = {
    baseUrl = "http://mango.pin:8012/v1";
    api = "openai-completions";
    apiKey = "LLAMA_SWAP_API_KEY";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = "gemma4:e4b";
        reasoning = true;
      }
    ];
  };

  # Shared llama-swap key (share = true; identical defs merge on mango with the
  # spaces `pi` service and the other personas).
  mkLlamaSwapKey = pkgs: {
    share = true;
    files."key" = { };
    files."env" = { };
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      key="sk-$(openssl rand -hex 32)"
      printf '%s' "$key" > "$out/key"
      printf 'LLAMA_SWAP_API_KEY=%s\n' "$key" > "$out/env"
    '';
  };

  # A bot on mango: Matrix @opencrow_<name>:pinpox.com, NATS (own nkey seed + nats
  # skill), and mango's llama-swap LLM.
  mkOpencrowInstance = name: {
    module.input = "self";
    module.name = "@pinpox/opencrow";
    roles.default.machines.mango.settings = {
      environment = {
        OPENCROW_MATRIX_HOMESERVER = "https://matrix.pinpox.com";
        OPENCROW_MATRIX_USER_ID = "@opencrow_${name}:pinpox.com";
        OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
        OPENCROW_PI_PROVIDER = "mango";
        OPENCROW_PI_MODEL = "gemma4:e4b";
        NATS_URL = "nats://kfbox.pin:4222";
        NATS_NKEY = "%d/nats-seed";
        OPENCROW_PI_SKILLS = "${self}/skills/nats";
      };
      piModels = mangoPiModels;
      matrixPasswordGenerator = "matrix-user-opencrow_${name}";
    };
    roles.default.extraModules = [
      (
        {
          config,
          pkgs,
          pinpox-utils,
          ...
        }:
        {
          clan.core.vars.generators."nats-key-opencrow-${name}" =
            import (self + "/clan-service-modules/nats/nkey.nix")
              {
                inherit pkgs;
                owner = "root";
              };
          clan.core.vars.generators."pi-llama-swap-key" = mkLlamaSwapKey pkgs;
          # Shared account password: created on the homeserver by the matrix
          # reconciler, used here to log in (OPENCROW_MATRIX_PASSWORD_FILE).
          clan.core.vars.generators."matrix-user-opencrow_${name}" = pinpox-utils.mkMatrixPassword;
          services.opencrow.instances.${name} = {
            extraPackages = [ pkgs.natscli ];
            # NKEY seed → systemd credential, read at %d/nats-seed (see NATS_NKEY).
            credentialFiles.nats-seed =
              config.clan.core.vars.generators."nats-key-opencrow-${name}".files.seed.path;
            environmentFiles = [
              config.clan.core.vars.generators."pi-llama-swap-key".files.env.path
            ];
          };
          containers."opencrow-${name}".config.networking.extraHosts = config.networking.extraHosts;
        }
      )
    ];
  };

  bots = {
    opencrow-one = mkOpencrowInstance "one";
    opencrow-two = mkOpencrowInstance "two";
  };

  # Broker authorization for one bot: its own opencrow.<name>.> namespace.
  mkNatsAuth = name: {
    permissions = {
      publish.allow = [ "opencrow.${name}.>" ];
      subscribe.allow = [ "opencrow.${name}.>" ];
    };
  };
in
bots
// {
  # Original bot on matrix.org/porree (kept verbatim; name = container/state dir).
  opencrow-claude = {
    module.input = "self";
    module.name = "@pinpox/opencrow";
    roles.default.machines.porree.settings.environment = {
      NEXTCLOUD_URL = "https://files.pablo.tools";
      NEXTCLOUD_USER = "pinpox";
      NEXTCLOUD_CALENDAR = "personal";
      WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
      WORK_NEXTCLOUD_USER = "pinpox";
      WORK_NEXTCLOUD_CALENDAR = "personal";
      OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
      OPENCROW_MATRIX_USER_ID = "@p.i.m.p.:matrix.org";
      OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
      OPENCROW_HEARTBEAT_INTERVAL = "30m";
    };
    roles.default.extraModules = [
      (
        { config, pinpox-utils, ... }:
        {
          clan.core.vars.generators."opencrow-nextcloud" = pinpox-utils.mkEnvGenerator [
            "NEXTCLOUD_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-nextcloud-work" = pinpox-utils.mkEnvGenerator [
            "WORK_NEXTCLOUD_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-eversports" = pinpox-utils.mkEnvGenerator [
            "EVERSPORTS_EMAIL"
            "EVERSPORTS_PASSWORD"
          ];
          # Integration env files, appended to the bot's token file (lists merge).
          services.opencrow.instances.claude.environmentFiles = [
            config.clan.core.vars.generators."opencrow-nextcloud".files.envfile.path
            config.clan.core.vars.generators."opencrow-nextcloud-work".files.envfile.path
            config.clan.core.vars.generators."opencrow-eversports".files.envfile.path
          ];
        }
      )
    ];
  };

  # Matrix accounts for the bots, deep-merged into the `matrix` instance.
  matrix.roles.server.machines.clementine.settings.users = map (
    n: builtins.replaceStrings [ "opencrow-" ] [ "opencrow_" ] n
  ) (builtins.attrNames bots);

  # NATS authorizations for the bots, deep-merged into the `nats` instance.
  nats.roles.server.settings.authorizations = builtins.listToAttrs (
    map (botName: {
      name = botName;
      value = mkNatsAuth (builtins.replaceStrings [ "opencrow-" ] [ "" ] botName);
    }) (builtins.attrNames bots)
  );
}
