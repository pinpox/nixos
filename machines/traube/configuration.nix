{
  pkgs,
  lib,
  opencrow,
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
            id = "qwen";
            name = "Qwen 2.5 7B (Local)";
            reasoning = false;
            input = [ "text" ];
            contextWindow = 131072;
            maxTokens = 16384;
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
      "131072"
      "--parallel"
      "2" # 2 slots to leave headroom on 32GB
      "--threads"
      "4" # generation: 4 big A720 cores only
      "--threads-batch"
      "8" # prompt processing: all 8 A720 cores
      "--cpu-range"
      "0-3,8-11" # pin to A720 cores (big+mid), skip A520 little cores (4-7)
      "--cpu-strict"
      "1" # strict core pinning
      "--flash-attn"
      "on" # faster prompt processing
      "--mlock" # prevent model eviction from RAM
      "--cache-type-k"
      "q8_0" # quantize KV cache (saves ~50% KV memory)
      "--cache-type-v"
      "q8_0"
      "--prio"
      "2" # higher process priority
    ];
    modelsPreset = {
      "qwen2.5-7b" = {
        hf-repo = "bartowski/Qwen2.5-7B-Instruct-GGUF";
        hf-file = "Qwen2.5-7B-Instruct-Q4_K_M.gguf";
        alias = "qwen";
        jinja = "on";
      };
    };
  };

  # OpenCrow bot using local llama-cpp (Nostr backend)
  clan.core.vars.generators."opencrow-traube" = {
    files.envfile = { };
    runtimeInputs = [ pkgs.coreutils pkgs.openssl ];
    script = ''
      mkdir -p $out
      KEY=$(openssl rand -hex 32)
      cat > $out/envfile <<EOT
      OPENCROW_NOSTR_PRIVATE_KEY='$KEY'
      EOT
    '';
  };

  services.opencrow = {
    enable = true;
    piPackage = pkgs.pi;
    extraPackages = [
      pkgs.curl
      pkgs.jq
    ];
    environmentFiles = [
      config.clan.core.vars.generators."opencrow-traube".files."envfile".path
    ];
    environment = {
      OPENCROW_BACKEND = "nostr";
      OPENCROW_NOSTR_RELAYS = "wss://nostr.0cx.de,wss://relay.damus.io,wss://relay.nostr.band,wss://nos.lol";
      OPENCROW_NOSTR_ALLOWED_USERS = "npub1evf9p0304tplxqdja8m2hjr9r77hmetz87nuexuc6fs07fnvapuqg5ak9j";
      OPENCROW_PI_PROVIDER = "llama-cpp";
      OPENCROW_PI_MODEL = "qwen";
      OPENCROW_HEARTBEAT_INTERVAL = "30m";
      OPENCROW_LOG_LEVEL = "debug";
      OPENCROW_PI_SKILLS_DIR = "/var/lib/opencrow/skills";
      OPENCROW_NOSTR_NAME = "opencrow";
      OPENCROW_NOSTR_DISPLAY_NAME = "OpenCrow";
      OPENCROW_NOSTR_ABOUT = "AI assistant powered by Qwen 2.5 7B";
    };
  };

  # Place models.json in PI_CODING_AGENT_DIR so pi finds the local provider
  systemd.tmpfiles.rules = [
    "L+ /var/lib/opencrow/pi-agent/models.json - - - - ${piModelsJson}"
  ];

  environment.systemPackages = [
    pkgs.llama-cpp
    pkgs.pi
  ];
}
