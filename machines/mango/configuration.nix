{
  lib,
  pkgs,
  config,
  spaces,
  pinpox-utils,
  ...
}:
let
  llamaServer = lib.getExe' config.services.llama-swap.llama-server-package "llama-server";

  # Weights live outside the store (multi-GB) and outside /home (the unit runs
  # with ProtectHome). Downloaded manually, see the model entry below.
  modelsDir = "/var/lib/models";
in
{

  imports = [
    ./disko-config-btrfs.nix
    # The LLM endpoint (http://mango.pin:8012/v1). Imported directly:
    # spaces-os deleted the `pi` clan service that used to pull this in, and
    # nothing else in the clan hosts llama-swap.
    spaces.nixosModules.llama-swap
    # nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  hardware = {
    # fw-fanctrl.enable = true;
    # amdgpu.opencl.enable = true;
    xone.enable = true;
  };

  networking.hostName = "mango";

  # Strix Halo unified-memory tuning: IOMMU off + 124 GiB GTT/TTM ceiling.
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=126976"
    "ttm.pages_limit=32505856"
  ];

  # Shared API key, required on every request — the endpoint is reachable from
  # the whole clan.
  clan.core.vars.generators."pi-llama-swap-key" = pinpox-utils.mkLlamaSwapKey;

  services.llama-swap = {
    enable = true;
    apiKeyEnvFile = config.clan.core.vars.generators."pi-llama-swap-key".files."env".path;
    # `[::]`, not `::`: the upstream module builds the flag by raw
    # concatenation (`--listen=${listenAddress}:${port}`), so the IPv6
    # wildcard must be bracketed or llama-swap crash-loops on ":::8012".
    listenAddress = lib.mkForce "[::]";
    # Fork-pinned build: the qwen4exp arch is not in any llama.cpp release
    # yet, and MTP speculative decoding for it is not merged upstream
    # (ggml-org/llama.cpp#27836).
    llama-server-package = pkgs.llama-cpp-qwen4exp;

    # Qwen3.8-Flash-Next 125B-A6B MoE + 51B n-gram table. Flags from
    # llama-bench sweeps on this box (Zulip: #topic-ai > qwen on FW desktop
    # tuning): -ub 2048 is +10% prefill (MoE, unlike the dense 27B's 256),
    # KV q8_0 is free, fa on a small win, threads irrelevant. Default mmap
    # keeps the sparsely-read n-gram table evictable instead of resident.
    # -np 1: multi-slot had an indexer-desync assert upstream; single slot
    # is the tested config.
    #
    # MTP speculative decoding (Zulip: #topic-ai > MTP for Qwen on FW
    # desktop): the model drafts its own next tokens via its NextN head, one
    # extra parallel pass verifies them. Measured on this box (greedy, 32K
    # ctx): file rewrite 22->53 t/s, new code 27->47, prose +12%, 7K-prompt
    # +39%; temp-1.0 sampling holds up. n-max 6 beat 3 and adding ngram-mod
    # was a wash, so MTP runs alone. Unsloth GGUFs are converted --no-nextn,
    # so the head comes from a detached sidecar (drluoto's Q8_0 export of the
    # official checkpoint) with its 3 duplicate legacy-named mixer tensors
    # (blk.48.nextn.hc_head_*) stripped -- this fork's loader rejects files
    # with unconsumed tensors.
    #
    # MTP entries run at reduced context: at 262K the sidecar overcommits
    # GTT -- RADV fails command submission and can leave llama-server wedged
    # in unkillable D-state (amdgpu/TTM livelock, reboot required). MTP is
    # therefore only on the default entry, at a context verified on this box;
    # the :262k entry keeps the full native context without MTP.
    settings.models =
      let
        qwenFlags = "-ngl 999 -fa on -np 1 -b 2048 -ub 2048 -ctk q8_0 -ctv q8_0 --jinja --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0";
        qwenDir = "${modelsDir}/Qwen3.8-Flash-Next-GGUF";
        mtpFlags = "-md ${qwenDir}/mtp-Qwen3.8-Flash-Next-Q8_0-stripped.gguf --spec-type draft-mtp --spec-draft-n-max 6 --spec-draft-p-min 0.7 -ctkd q8_0 -ctvd q8_0";
      in
      {
        # Default: 31-53 t/s tg with MTP (22-28 without) / 427 t/s pp2048.
        "qwen3.8-flash-next:iq4_xs" = {
          cmd = "${llamaServer} -m ${qwenDir}/UD-IQ4_XS/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf --port \${PORT} -c 131072 ${qwenFlags} ${mtpFlags}";
          aliases = [ "qwen3.8-flash-next" ];
        };
        # Full native 262K context, no MTP: 24.1 t/s tg, ~101 GiB total.
        "qwen3.8-flash-next:iq4_xs-262k".cmd =
          "${llamaServer} -m ${qwenDir}/UD-IQ4_XS/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf --port \${PORT} -c 262144 ${qwenFlags}";
        # Quality-max dynamic quant: 23 t/s tg / 421 t/s pp2048. 131K ctx —
        # 262K would leave <5 GiB free.
        "qwen3.8-flash-next:q4_k_xl".cmd =
          "${llamaServer} -m ${qwenDir}/UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf --port \${PORT} -c 131072 ${qwenFlags}";
        # Fast option: 28.3 t/s tg / 442 t/s pp2048, 21/16.2 t/s at 8K/32K.
        "qwen3.8-flash-next:q2_k_xl".cmd =
          "${llamaServer} -m ${qwenDir}/UD-Q2_K_XL/Qwen3.8-Flash-Next-UD-Q2_K_XL-00001-of-00003.gguf --port \${PORT} -c 262144 ${qwenFlags}";
      };
  };
  networking.firewall.allowedTCPPorts = [ config.services.llama-swap.port ];

  home-manager.users.pinpox.pinpox.programs.games.enable = true;

  programs = {

    # Games
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    gamemode = {
      enable = true;
      settings.custom = {
        # Keep the screen awake while gaming.
        start = "${pkgs.systemd}/bin/systemd-run --user --unit=gaming-wlinhibit --collect ${pkgs.wlinhibit}/bin/wlinhibit";
        end = "${pkgs.systemd}/bin/systemctl --user stop gaming-wlinhibit";
      };
    };
  };
}
