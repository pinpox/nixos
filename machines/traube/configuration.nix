{
  pkgs,
  lib,
  opencrow,
  mics-skills,
  pinpox-utils,
  config,
  ...
}:
let
  # models.json for pi to discover the local llama-cpp provider
  piModelsJson = pkgs.writeText "models.json" (
    builtins.toJSON {
      providers.llama-cpp = {
        baseUrl = "http://127.0.0.1:8080/v1";
        api = "openai-completions";
        apiKey = "dummy";
        models = [
          {
            id = "hermes";
            name = "Hermes 3 Llama 3.1 8B (Local)";
            reasoning = false;
            input = [ "text" ];
            contextWindow = 16384;
            maxTokens = 4096;
          }
        ];
      };
    }
  );
in
{
  imports = [ ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # Lock CPU governor to performance mode (avoid frequency scaling latency)
  powerManagement.cpuFreqGovernor = "performance";

  # Transparent huge pages for large model allocations (reduces TLB misses)
  boot.kernel.sysctl = {
    "vm.swappiness" = 0; # never swap model data
  };

  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    extraFlags = [
      "--ctx-size"
      "16384"
      "--parallel"
      "1" # single slot, only used by opencrow
      "--batch-size"
      "2048"
      "--mlock" # prevent model eviction from RAM
      "--cache-type-k"
      "q8_0" # quantize KV cache (saves ~50% KV memory)
      "--cache-type-v"
      "q8_0"
      "--prio"
      "2" # higher process priority
    ];
    modelsPreset = {
      "hermes-3-8b" = {
        hf-repo = "NousResearch/Hermes-3-Llama-3.1-8B-GGUF";
        hf-file = "Hermes-3-Llama-3.1-8B.Q4_K_M.gguf";
        alias = "hermes";
        jinja = "on";
      };
    };
  };

  # Allow llama-cpp to mlock the full model into RAM
  systemd.services.llama-cpp.serviceConfig.LimitMEMLOCK = "infinity";

  # OpenCrow bot using local llama-cpp (Matrix backend)
  clan.core.vars.generators."opencrow-traube" = pinpox-utils.mkEnvGenerator [
    "OPENCROW_MATRIX_ACCESS_TOKEN"
  ];

  services.opencrow = {
    enable = true;
    piPackage = pkgs.pi;
    extraPackages = [
      pkgs.pi
      pkgs.curl
      pkgs.jq
      mics-skills.packages.${pkgs.system}.db-cli
    ];
    environmentFiles = [
      config.clan.core.vars.generators."opencrow-traube".files."envfile".path
    ];
    environment = {
      OPENCROW_BACKEND = "matrix";
      OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
      OPENCROW_MATRIX_USER_ID = "@c.h.i.m.p.:matrix.org";
      OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
      OPENCROW_PI_PROVIDER = "llama-cpp";
      OPENCROW_PI_MODEL = "hermes";
      OPENCROW_HEARTBEAT_INTERVAL = "30m";
      OPENCROW_LOG_LEVEL = "debug";
    };
    skills = {
      db-cli = "${mics-skills}/skills/db-cli";
    };
  };

  # Place models.json in PI_CODING_AGENT_DIR so pi finds the local provider
  # Symlink skill directories into OPENCROW_PI_SKILLS_DIR
  systemd.tmpfiles.rules = [
    "L+ /var/lib/opencrow/pi-agent/models.json - - - - ${piModelsJson}"
  ];

  environment.systemPackages = [
    pkgs.llama-cpp
    pkgs.pi
  ];
}
