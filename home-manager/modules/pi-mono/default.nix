{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.pi;

  # Generate models.json from the declarative provider config
  modelsJson = pkgs.writeText "models.json" (
    builtins.toJSON { providers = cfg.providers; }
  );
in
{
  options.pinpox.programs.pi = {

    enable = mkEnableOption "pi coding agent";

    package = mkOption {
      type = types.package;
      default = pkgs.pi;
      description = "The pi package to install.";
    };

    extensions = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = ''
        Extension name to source path mappings. Each entry is symlinked into
        `~/.pi/agent/extensions/<name>`. Sources can be local paths, fetchGit
        results, or built packages.

        Pi auto-discovers extensions from `~/.pi/agent/extensions/` — both
        single `.ts` files and directories with an `index.ts` entry point.

        Note: Extensions that require `npm install` (i.e. have runtime
        dependencies in package.json) need to be built first or installed
        via `pi install` instead.
      '';
      example = literalExpression ''
        {
          my-extension = ./extensions/my-extension.ts;
        }
      '';
    };

    providers = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Model provider configurations, keyed by provider name. All providers
        are merged and written to `~/.pi/agent/models.json` as a read-only
        symlink. Pi only reads this file, never writes to it.

        Can be set from multiple modules (e.g. machine-specific configs)
        and Nix will merge them.
      '';
      example = literalExpression ''
        {
          ollama = {
            baseUrl = "http://100.96.100.103:11434/v1";
            api = "openai-completions";
            apiKey = "dummy";
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
            };
            models = [
              { id = "llama3.3:latest"; contextWindow = 128000; maxTokens = 32000; }
            ];
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {

    home.packages = [ cfg.package ];

    home.file = mkMerge [
      # Symlink extensions into the auto-discovery directory
      (mapAttrs' (name: src: {
        name = ".pi/agent/extensions/${name}";
        value.source = src;
      }) cfg.extensions)

      # models.json as read-only symlink (only when providers are configured)
      (mkIf (cfg.providers != { }) {
        ".pi/agent/models.json".source = modelsJson;
      })
    ];
  };
}
