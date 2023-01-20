{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.woodpecker-agent;
  servercfg = config.services.woodpecker-server;
in
{
  options = {
    services.woodpecker-agent = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc "Enable Woodpecker agent.";
      };

      package = mkOption {
        default = pkgs.woodpecker-agent;
        type = types.package;
        defaultText = literalExpression "pkgs.woodpecker-agent";
        description = lib.mdDoc "woodpecker-agent derivation to use";
      };

      user = mkOption {
        type = types.str;
        default = "woodpecker-agent";
        description = lib.mdDoc "User account under which woodpecker agent runs.";
      };

      agentSecretFile = mkOption {
        type = types.nullOr types.path;
        default = servercfg.agentSecretFile;
        description = lib.mdDoc "Read the agent secret from this file path.";
      };

      maxProcesses = mkOption {
        type = types.int;
        default = 1;
        description = lib.mdDoc "The maximum number of processes per agent.";
      };

      backend = mkOption {
        type = types.enum [ "auto-detect" "docker" "local" "ssh" ];
        default = "auto-detect";
        description = lib.mdDoc "Configures the backend engine to run pipelines on.";
      };

      server = mkOption {
        type = types.str;
        default = "127.0.0.1:${if servercfg.enable then toString servercfg.gRPCPort else "9000"}";
        description = lib.mdDoc "The gPRC address of the server.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.woodpecker-agent = {
      description = "woodpecker-agent";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.woodpecker-plugin-git
        pkgs.bash
        pkgs.git
        pkgs.gzip
        pkgs.nixUnstable
      ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "woodpecker-agent";
        ExecStart = "${cfg.package}/bin/woodpecker-agent";
        Restart = "always";
        # TODO add security/sandbox params.

        # EnvironmentFile = [ config.lollypops.secrets.files."woodpecker/agent-envfile".path ];
      };
      environment = mkMerge [
        {
          WOODPECKER_MAX_WORKFLOWS = "3";
          WOODPECKER_SERVER = cfg.server;
          WOODPECKER_MAX_PROCS = toString cfg.maxProcesses;
          WOODPECKER_BACKEND = cfg.backend;

          # TODO remove
          WOODPECKER_LOG_LEVEL = "debug";
          WOODPECKER_DEBUG_PRETTY = "true";
          WOODPECKER_HEALTHCHECK_ADDR = "localhost:3003";

        }
        (mkIf (cfg.agentSecretFile != null) {
          WOODPECKER_AGENT_SECRET_FILE = cfg.agentSecretFile;
        })
      ];
    };

    users.users = mkIf (cfg.user == "woodpecker-agent") {
      woodpecker-agent = {
        # createHome = true;
        # home = cfg.stateDir;
        useDefaultShell = true;
        group = "woodpecker-agent";
        extraGroups = [ "woodpecker" ];
        isSystemUser = true;
      };
    };
    users.groups.woodpecker-agent = { };
  };
}
