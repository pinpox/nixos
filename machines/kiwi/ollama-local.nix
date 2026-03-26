{
  nixos-hardware,
  lib,
  pkgs,
  ...
}:

let

  vllmProvider = host: model: {
    baseUrl = "http://${host}:8000/v1";
    api = "openai-completions";
    apiKey = "dummy";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = model;
        reasoning = true;
      }
    ];
  };

in
{
  services.tailscale.enable = true;

  # Pi providers via home-manager module
  home-manager.users.pinpox.pinpox.programs.pi.providers = {
    llama-cpp = {
      baseUrl = "http://127.0.0.1:8080/v1";
      api = "openai-completions";
      apiKey = "dummy";
      models = [
        {
          id = "glm-4.7-flash";
          name = "GLM-4.7 Flash (Local)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 32768;
          maxTokens = 8192;
        }
      ];
    };
    vllm_1 = vllmProvider "100.96.100.100" "openai/gpt-oss-120b";
    vllm_2 = vllmProvider "100.96.100.101" "openai/gpt-oss-120b";
    vllm_3 = vllmProvider "100.96.100.102" "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8";
    # Pull models with: OLLAMA_HOST="100.96.100.103:11434" ollama pull <model>
    ollama = {
      baseUrl = "http://100.96.100.103:11434/v1";
      api = "openai-completions";
      apiKey = "dummy";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };
      models = [
        {
          id = "codegemma:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M_131072";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M_16384";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M_32768";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M_65536";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-0528-q4_K_M_8192";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:671b-q4_K_M";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:70b";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-r1:latest";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-v3.1:671b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-v3.1:671b_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "deepseek-v3.1:671b_163840";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "devstral:24b-small-2505-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "gemma3:27b-it-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "glm-4.7-flash:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "glm-5:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "gpt-oss:120b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "gpt-oss:120b_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "gpt-oss:120b-cloud";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "gpt-oss:20b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "hf.co/mradermacher/Qwen3.5-397B-A17B-GGUF:Qwen3.5-397B-A17B.Q3_K_M.gguf";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "hf.co/sebsigma/SemanticCite-Checker-Qwen3-4B:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "hf.co/sebsigma/SemanticCite-Refiner-Qwen3-1B:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "hf.co/unsloth/GLM-5-GGUF:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "hf.co/unsloth/MiniMax-M2.5-GGUF:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "jmorgan/bespoke-minicheck:7b-fp16";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "jmorgan/bespoke-minicheck:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama3.2:1b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama3.2:3b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama3.3:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:128x17b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:17b-maverick-128e-instruct-q4_K_M";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:17b-maverick-128e-instruct-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:maverick";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:maverick_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:maverick_262144";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:maverick_32768";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "llama4:scout";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "ministral-3:14b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mistral:7b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mistral:7b_32768";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mistral-nemo:12b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mistral-nemo:12b_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mistral-small3.2:24b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mixtral:8x22b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "mixtral:8x22b_65536";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "my-model:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "phi4:14b-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen2.5-coder:32b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen2.5-coder:32b-instruct-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3:235b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3:32b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3:32b_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3:32b-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3.5:397b-q3_k_m";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b-a3b-fp16";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b-a3b-q4_K_M";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b-a3b-q4_K_M_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b-a3b-q4_K_M_65536";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:30b-a3b-q8_0";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:480b";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder:480b_131072";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "SemanticCite-Checker-Qwen3-4B:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "SemanticCite-Refiner-Qwen3-1B:latest";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "tinyllama:1.1b-chat-v1-q2_K";
          contextWindow = 128000;
          maxTokens = 32000;
        }
        {
          id = "qwen3.5:122b";
          contextWindow = 256000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-coder-next:q8_0";
          contextWindow = 256000;
          maxTokens = 32000;
        }
        {
          id = "qwen3-next:80b";
          contextWindow = 256000;
          maxTokens = 32000;
        }
        {
          id = "sinhang/QWen35-27b-q4_K_M-Claude";
          reasoning = true;
          contextWindow = 128000;
          maxTokens = 32000;
        }
      ];
    };
  };

}
