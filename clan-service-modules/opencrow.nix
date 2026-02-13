{ ... }:
{
  _class = "clan.service";
  manifest.name = "opencrow";
  manifest.description = "OpenCrow Matrix bot bridging messages to an AI coding agent via pi RPC";
  manifest.readme = "Matrix chat bot that forwards messages to a pi coding agent subprocess per room";
  manifest.categories = [ "Communication" ];

  roles.default = {
    description = "Sets up OpenCrow in a NixOS container";
    interface =
      { lib, ... }:
      {
        options = {
          piModel = lib.mkOption {
            type = lib.types.str;
            default = "claude-sonnet-4-5-20250929";
            description = "Model ID for pi to use";
          };

          piProvider = lib.mkOption {
            type = lib.types.str;
            default = "anthropic";
            description = "LLM provider for pi (anthropic, openai, google, etc.)";
          };

          matrixHomeserver = lib.mkOption {
            type = lib.types.str;
            default = "https://matrix.org";
            description = "Matrix homeserver URL";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            opencrow,
            ...
          }:
          let
            pinpox-utils = import ../utils { inherit pkgs; };
            system = pkgs.stdenv.hostPlatform.system;
            opencrowPkg = opencrow.packages.${system}.opencrow;
            envfilePath = config.clan.core.vars.generators."opencrow".files."envfile".path;
          in
          {
            config = {

              # Secrets via clan vars
              clan.core.vars.generators."opencrow" = pinpox-utils.mkEnvGenerator [
                "ANTHROPIC_API_KEY"
                "OPENCROW_MATRIX_ACCESS_TOKEN"
                "OPENCROW_MATRIX_USER_ID"
              ];

              # State directory on host (bind-mounted into container)
              systemd.tmpfiles.rules = [
                "d /var/lib/opencrow 0750 root root -"
              ];

              containers.opencrow = {
                autoStart = true;
                privateNetwork = false;

                bindMounts = {
                  "/var/lib/opencrow" = {
                    hostPath = "/var/lib/opencrow";
                    isReadOnly = false;
                  };
                  "/run/secrets/opencrow-envfile" = {
                    hostPath = envfilePath;
                    isReadOnly = true;
                  };
                };

                config =
                  { ... }:
                  {
                    system.stateVersion = "25.05";

                    systemd.services.opencrow = {
                      description = "OpenCrow Matrix Bot";
                      wantedBy = [ "multi-user.target" ];
                      after = [ "network-online.target" ];
                      wants = [ "network-online.target" ];

                      environment = {
                        OPENCROW_MATRIX_HOMESERVER = settings.matrixHomeserver;
                        OPENCROW_PI_PROVIDER = settings.piProvider;
                        OPENCROW_PI_MODEL = settings.piModel;
                        OPENCROW_PI_SESSION_DIR = "/var/lib/opencrow/sessions";
                        OPENCROW_PI_WORKING_DIR = "/var/lib/opencrow";
                        OPENCROW_PI_SKILLS = "${opencrowPkg}/share/opencrow/skills/web";
                        PI_CODING_AGENT_DIR = "/var/lib/opencrow/pi-agent";
                      };

                      serviceConfig = {
                        EnvironmentFile = "/run/secrets/opencrow-envfile";
                        ExecStart = lib.getExe opencrowPkg;
                        Restart = "on-failure";
                        RestartSec = "10s";
                        WorkingDirectory = "/var/lib/opencrow";
                      };
                    };

                    # pi must be on PATH for opencrow to spawn it
                    # TODO: add pi to this list once it is packaged
                    environment.systemPackages = [ opencrowPkg ];
                  };
              };
            };
          };
      };
  };
}
