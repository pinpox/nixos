{ ... }:
# OpenCrow messaging-bot instances as a clan service. Each clan-service INSTANCE
# maps to one `services.opencrow.instances.<instanceName>` from the upstream
# opencrow flake — one omp-backed agent on a messaging backend, running in its
# own sandboxed systemd-nspawn container (state in /var/lib/opencrow-<name>).
#
# Declare instances from the inventory; `settings` carry only plain values:
# the per-instance environment, which clan-vars generators hold its secrets,
# extension toggles and omp config. Everything that needs `pkgs`/flake inputs
# (the opencrow + omp packages, the web + deutschebahn skills, db-cli) is wired
# here, so the inventory stays free of package references.
{
  _class = "clan.service";
  manifest.name = "opencrow";
  manifest.description = "OpenCrow bot instances — one omp agent per instance in a sandboxed container.";
  manifest.categories = [ "Utility" ];
  manifest.readme = ''
    One clan-service instance per OpenCrow bot. Point an `instances.<name>` of
    `@pinpox/opencrow` at a machine and set `roles.default...settings`:

    - `environment`: OPENCROW_*/provider env vars (strings).
    - `environmentFileGenerators`: names of clan-vars generators whose
      `envfile` holds this instance's secrets (Matrix token, API keys, …);
      resolved to file paths on the target machine.
    - `extensions` / `piSettings` / `piModels`: forwarded to omp.

    Each instance runs in its own nspawn container. The host opencrow package,
    omp, the web + deutschebahn skills and db-cli are wired in automatically.
  '';

  # Import the upstream opencrow NixOS module once per machine (doing it in
  # perInstance would re-declare the `services.opencrow` option and error), and
  # declare the instance secrets here — they belong with the service, not a
  # separate module. Matrix tokens are per-bot (`opencrow` = claude/P.I.M.P.,
  # `opencrow-local` = local/CHIMP); nextcloud/eversports are shared across
  # bots. `pi-llama-swap-key` is the shared twin of the spaces `pi` service's
  # generator (auto-generated, share = true) so this box holds the same key.
  # Inventory wires them in by name via `environmentFileGenerators`.
  perMachine = {
    nixosModule =
      {
        pkgs,
        opencrow,
        pinpox-utils,
        ...
      }:
      {
        imports = [ opencrow.nixosModules.default ];

        clan.core.vars.generators = {
          "opencrow" = pinpox-utils.mkEnvGenerator [
            "OPENCROW_MATRIX_ACCESS_TOKEN"
            "OPENCROW_MATRIX_USER_ID"
          ];
          "opencrow-local" = pinpox-utils.mkEnvGenerator [
            "OPENCROW_MATRIX_ACCESS_TOKEN"
          ];
          "opencrow-nextcloud" = pinpox-utils.mkEnvGenerator [
            "NEXTCLOUD_PASSWORD"
          ];
          "opencrow-nextcloud-work" = pinpox-utils.mkEnvGenerator [
            "WORK_NEXTCLOUD_PASSWORD"
          ];
          "opencrow-eversports" = pinpox-utils.mkEnvGenerator [
            "EVERSPORTS_EMAIL"
            "EVERSPORTS_PASSWORD"
          ];
          # Identical twin of the spaces `pi` service's pi-llama-swap-key
          # (share = true): declares no new secret, just receives the same
          # auto-generated shared key. Keep in lockstep with that definition.
          "pi-llama-swap-key" = {
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
        };
      };
  };

  roles.default = {
    description = "One OpenCrow bot instance (an omp agent on a messaging backend).";

    interface =
      { lib, ... }:
      {
        options = {
          environment = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = ''
              Environment variables for this instance (OPENCROW_* and provider
              settings). Forwarded to
              `services.opencrow.instances.<name>.environment`. Do not set
              OPENCROW_PI_SKILLS_DIR — it is derived from the wired-in skills.
            '';
            example = lib.literalExpression ''
              {
                OPENCROW_BACKEND = "matrix";
                OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
                OPENCROW_HEARTBEAT_INTERVAL = "30m";
              }
            '';
          };

          environmentFileGenerators = lib.mkOption {
            type = lib.types.listOf (
              lib.types.either lib.types.str (
                lib.types.submodule {
                  options = {
                    generator = lib.mkOption {
                      type = lib.types.str;
                      description = "Clan vars generator name.";
                    };
                    file = lib.mkOption {
                      type = lib.types.str;
                      default = "envfile";
                      description = "Which generator file to load as the env file.";
                    };
                  };
                }
              )
            );
            default = [ ];
            description = ''
              Clan vars generators whose secret env file is loaded for this
              instance (resolved to the file path on the target machine). A bare
              string uses the generator's `envfile` (the mkEnvGenerator
              convention); use `{ generator; file; }` when the env file has a
              different name (e.g. the shared `pi-llama-swap-key` exposes `env`).
            '';
            example = lib.literalExpression ''[ "opencrow" { generator = "pi-llama-swap-key"; file = "env"; } ]'';
          };

          extensions = lib.mkOption {
            type = lib.types.attrsOf (lib.types.either lib.types.bool lib.types.path);
            default = { };
            description = ''
              omp extensions: `<name> = true` enables a packaged extension
              (e.g. memory, reminders), a path loads a custom one.
            '';
          };

          piSettings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Extra keys merged into omp's config.yml.";
          };

          piModels = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Contents of omp's models.yml (custom providers / model overrides).";
          };
        };
      };

    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            opencrow,
            mics-skills,
            ...
          }:
          let
            # The upstream module names the container/state dir as
            # "opencrow-<name>"; strip a leading "opencrow-" from the clan
            # instance name so an inventory key like "opencrow-claude" maps to
            # container "opencrow-claude" (state /var/lib/opencrow-claude), not
            # a doubled "opencrow-opencrow-claude".
            instName = lib.removePrefix "opencrow-" instanceName;
            system = pkgs.stdenv.hostPlatform.system;
            opencrowPkg = opencrow.packages.${system}.opencrow;
          in
          {
            services.opencrow.instances.${instName} = {
              enable = true;
              piPackage = pkgs.omp;
              extraPackages = [
                pkgs.omp
                pkgs.curl
                pkgs.jq
                mics-skills.packages.${system}.db-cli
              ];
              skills = {
                web = "${opencrowPkg}/share/opencrow/skills/web";
                deutschebahn = "${mics-skills}/skills/db-cli";
              };
              environment = settings.environment;
              environmentFiles = map (
                g:
                if builtins.isString g then
                  config.clan.core.vars.generators.${g}.files.envfile.path
                else
                  config.clan.core.vars.generators.${g.generator}.files.${g.file}.path
              ) settings.environmentFileGenerators;
              extensions = settings.extensions;
              piSettings = settings.piSettings;
              piModels = settings.piModels;
            };
          };
      };
  };
}
