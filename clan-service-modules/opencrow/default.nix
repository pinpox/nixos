{ ... }:
# OpenCrow messaging-bot instances as a clan service. Each clan-service INSTANCE
# maps to one `services.opencrow.instances.<instanceName>` from the upstream
# opencrow flake — one omp-backed agent on a messaging backend, running in its
# own sandboxed systemd-nspawn container (state in /var/lib/opencrow-<name>).
#
# Declare instances from the inventory; `settings` carry only plain values:
# the per-instance environment, extension toggles and omp config. Package and
# flake-input wiring (the opencrow + omp packages, the default `web` skill and
# the bundled `memory` extension) lives here, so the inventory stays free of
# package references. Per-instance secrets are clan-vars generators declared in
# the instance's `extraModules`, which also wires them into `environmentFiles`.
{
  _class = "clan.service";
  manifest.name = "opencrow";
  manifest.description = "OpenCrow bot instances — one omp agent per instance in a sandboxed container.";
  manifest.categories = [ "Utility" ];
  manifest.readme = ''
    One clan-service instance per OpenCrow bot. Point an `instances.<name>` of
    `@pinpox/opencrow` at a machine and set `roles.default...settings`:

    - `environment`: OPENCROW_*/provider env vars (strings).
    - `extensions` / `piSettings` / `piModels`: forwarded to omp.

    The bot's own Matrix-token generator (`opencrow-<name>`) is declared here
    and its env file wired automatically. Shared secrets (nextcloud, eversports,
    …) are clan-vars generators declared in the instance's `extraModules`, which
    also appends them to `services.opencrow.instances.<name>.environmentFiles`
    (the list-typed option merges with the token file wired here).

    Each instance runs in its own nspawn container. The host opencrow package,
    omp, the default `web` skill and the bundled `memory` extension are wired
    in automatically; integration-specific skills are not the service's job.
  '';

  # Import the upstream opencrow NixOS module once per machine — doing it in
  # perInstance would re-declare the `services.opencrow` option and error.
  # Per-instance secrets are declared in `roles.default.perInstance`, so a
  # machine only gets the clan-vars generators of the bots it actually runs.
  perMachine = {
    nixosModule =
      { opencrow, ... }:
      {
        imports = [ opencrow.nixosModules.default ];
      };
  };

  roles.default = {
    description = "Sets up a OpenCrow bot instance";

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

          matrixPasswordGenerator = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Clan-vars generator (with a `password` file) to log in with for the
              Matrix token (OPENCROW_MATRIX_PASSWORD_FILE), instead of the prompted
              `opencrow-<name>` OPENCROW_MATRIX_ACCESS_TOKEN generator.
            '';
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
            pinpox-utils,
            ...
          }:
          let
            instName = lib.removePrefix "opencrow-" instanceName;
            tokenGenerator = "opencrow-${instName}";
            # Password login (file) instead of a prompted access-token generator.
            usePassword = settings.matrixPasswordGenerator != null;
          in
          {
            services.opencrow.instances.${instName} = {
              enable = true;
              piPackage = pkgs.omp;
              extraPackages = [
                pkgs.omp
                pkgs.curl
                pkgs.jq
              ];
              environment =
                settings.environment
                // lib.optionalAttrs usePassword {
                  OPENCROW_MATRIX_PASSWORD_FILE = "%d/matrix-password";
                };
              # Token path: the bot's own Matrix-token env file (shared-secret env
              # files are appended by the instance's extraModules). Password path:
              # the account password as a credential; opencrow mints the token.
              environmentFiles = lib.optional (!usePassword) (
                config.clan.core.vars.generators.${tokenGenerator}.files.envfile.path
              );
              credentialFiles = lib.optionalAttrs usePassword {
                matrix-password =
                  config.clan.core.vars.generators.${settings.matrixPasswordGenerator}.files.password.path;
              };

              extensions = {
                # `web` skill is enabled by the upstream default
                memory = true;
              }
              // settings.extensions;
              piSettings = settings.piSettings;
              piModels = settings.piModels;
            };

            # Prompted Matrix-token generator — only when not using password login.
            clan.core.vars.generators = lib.optionalAttrs (!usePassword) {
              ${tokenGenerator} = pinpox-utils.mkEnvGenerator [ "OPENCROW_MATRIX_ACCESS_TOKEN" ];
            };
          };
      };
  };
}
