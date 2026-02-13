{ ... }:
{
  _class = "clan.service";
  manifest.name = "openclaw";
  manifest.description = "OpenClaw AI assistant gateway";
  manifest.readme = "Personal AI assistant gateway with Matrix integration";
  manifest.categories = [ "Communication" ];
  manifest.exports.out = [ "endpoints" ];

  roles.default = {
    description = "Sets up OpenClaw gateway with caddy reverse proxy";
    interface =
      { lib, meta, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "claw.${meta.domain}";
            description = "Host serving the OpenClaw gateway";
          };

          matrixHomeserver = lib.mkOption {
            type = lib.types.str;
            default = "https://matrix.org";
            description = "Matrix homeserver URL";
          };

          matrixDmPolicy = lib.mkOption {
            type = lib.types.enum [
              "pairing"
              "allowlist"
              "open"
              "disabled"
            ];
            default = "pairing";
            description = "DM access control policy for Matrix";
          };

          model = lib.mkOption {
            type = lib.types.str;
            default = "anthropic/claude-sonnet-4-5";
            description = "Primary model in provider/model format";
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      {
        exports = mkExports { endpoints.hosts = [ settings.host ]; };

        nixosModule =
          {
            config,
            pkgs,
            nix-openclaw,
            ...
          }:
          let
            pinpox-utils = import ../utils { inherit pkgs; };

            openclawConfig = pkgs.writeText "openclaw.json" (builtins.toJSON {
              agents.defaults.model.primary = settings.model;
              channels.matrix = {
                enabled = true;
                homeserver = settings.matrixHomeserver;
                userId = "\${MATRIX_USER_ID}";
                accessToken = "\${MATRIX_ACCESS_TOKEN}";
                dm.policy = settings.matrixDmPolicy;
              };
            });
          in
          {
            config = {
              # Reverse proxy
              services.caddy = {
                enable = true;
                virtualHosts."${settings.host}".extraConfig =
                  "reverse_proxy 127.0.0.1:3000";
              };

              # Secrets via clan vars
              clan.core.vars.generators."openclaw" = pinpox-utils.mkEnvGenerator [
                "ANTHROPIC_API_KEY"
                "MATRIX_ACCESS_TOKEN"
                "MATRIX_USER_ID"
              ];

              # System user
              users.users.openclaw = {
                isSystemUser = true;
                group = "openclaw";
                home = "/var/lib/openclaw";
                createHome = true;
              };
              users.groups.openclaw = { };

              # Gateway systemd service
              systemd.services.openclaw-gateway = {
                description = "OpenClaw AI Gateway";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];

                environment = {
                  OPENCLAW_STATE_DIR = "/var/lib/openclaw";
                  OPENCLAW_CONFIG_PATH = "/var/lib/openclaw/openclaw.json";
                  OPENCLAW_NIX_MODE = "1";
                  NODE_ENV = "production";
                };

                preStart = ''
                  cp --no-preserve=mode ${openclawConfig} /var/lib/openclaw/openclaw.json
                '';

                serviceConfig = {
                  EnvironmentFile =
                    config.clan.core.vars.generators."openclaw".files."envfile".path;
                  ExecStart =
                    "${nix-openclaw.packages.x86_64-linux.default}/bin/openclaw gateway";
                  Restart = "on-failure";
                  RestartSec = "5s";
                  User = "openclaw";
                  Group = "openclaw";
                  WorkingDirectory = "/var/lib/openclaw";
                  StateDirectory = "openclaw";

                  # Hardening
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  PrivateDevices = true;
                  ProtectSystem = "strict";
                  ProtectHome = true;
                  ProtectKernelTunables = true;
                  ProtectKernelModules = true;
                  ProtectControlGroups = true;
                  ReadWritePaths = [ "/var/lib/openclaw" ];
                  MemoryDenyWriteExecute = false; # Node.js JIT
                };
              };
            };
          };
      };
  };
}
