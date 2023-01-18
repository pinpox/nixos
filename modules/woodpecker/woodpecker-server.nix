{ config, lib, options, pkgs, ... }:

with lib;

let
  cfg = config.services.woodpecker-server;
  useMysql = cfg.database.type == "mysql";
  usePostgresql = cfg.database.type == "postgres";
  useSqlite = cfg.database.type == "sqlite3";
in
{
  options = {
    services.woodpecker-server = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc "Enable Woodpecker Server.";
      };

      package = mkOption {
        default = pkgs.woodpecker-server;
        type = types.package;
        defaultText = literalExpression "pkgs.woodpecker-server";
        description = lib.mdDoc "woodpecker-server derivation to use";
      };

      stateDir = mkOption {
        default = "/var/lib/woodpecker-server";
        type = types.str;
        description = lib.mdDoc "woodpecker server data directory.";
      };

      user = mkOption {
        type = types.str;
        default = "woodpecker-server";
        description = lib.mdDoc "User account under which woodpecker server runs.";
      };

      rootUrl = mkOption {
        default = "http://localhost:3030";
        type = types.str;
        description = lib.mkDoc "Full public URL of Woodpecker server";
      };

      httpPort = mkOption {
        type = types.port;
        default = 3030;
        description = lib.mdDoc "HTTP listen port.";
      };

      gRPCPort = mkOption {
        type = types.port;
        default = 9000;
        description = lib.mdDoc "The gPRC listener port.";
      };

      admins = mkOption {
        default = "";
        type = types.str;
        description = lib.mdDoc "Woodpecker admin users.";
      };

      agentSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc "Read the agent secret from this file path.";
      };

      database = {
        type = mkOption {
          type = types.enum [ "sqlite3" "mysql" "postgres" ];
          example = "mysql";
          default = "sqlite3";
          description = lib.mdDoc "Database engine to use.";
        };

        host = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = lib.mdDoc "Database host address.";
        };

        port = mkOption {
          type = types.port;
          default = (if !usePostgresql then 3306 else config.services.postgresql.port);
          defaultText = literalExpression ''
            if config.${opt.database.type} != "postgresql"
            then 3306
            else config.${options.services.postgresql.port}
          '';
          description = lib.mdDoc "Database host port.";
        };

        name = mkOption {
          type = types.str;
          default = "woodpecker_server";
          description = lib.mdDoc "Database name.";
        };

        password = mkOption {
          type = types.str;
          default = "";
          description = lib.mdDoc ''
            The password corresponding to {option}`database.user`.
            Warning: this is stored in cleartext in the Nix store!
            Use {option}`database.passwordFile` instead.
          '';
        };

        user = mkOption {
          type = types.str;
          default = "woodpecker-server";
          description = lib.mdDoc "Database user.";
        };

        socket = mkOption {
          type = types.nullOr types.path;
          default = if (cfg.database.createDatabase && usePostgresql) then "/run/postgresql" else if (cfg.database.createDatabase && useMysql) then "/run/mysqld/mysqld.sock" else null;
          defaultText = literalExpression "null";
          example = "/run/mysqld/mysqld.sock";
          description = lib.mdDoc "Path to the unix socket file to use for authentication.";
        };

        createDatabase = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Whether to create a local database automatically.";
        };
      };

      limitMem = mkOption {
        type = types.int;
        default = 0;
        description = lib.mdDoc "The maximum amount of memory a single pipeline container can use, configured in bytes. There is no limit if 0.";
      };

      limitSwap = mkOption {
        type = types.int;
        default = 0;
        description = lib.mdDoc "The maximum amount of memory a single pipeline container is allowed to swap to disk, configured in bytes. There is no limit if 0.";
      };

      limitCPU = mkOption {
        type = types.int;
        default = 0;
        description = lib.mdDoc "The number of microseconds per CPU period that the container is limited to before throttled. There is no limit if 0.";
      };

      useGitea = mkOption {
        default = config.services.gitea.enable;
        type = types.bool;
        description = lib.mkDoc "Whether to integrate with gitea.";
      };

      giteaUrl = mkOption {
        default = config.services.gitea.rootUrl;
        type = types.str;
        description = lib.mkDoc "Full public URL of gitea server.";
      };

      giteaClientIdFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };

      giteaClientSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.database.createDatabase -> cfg.database.user == cfg.user;
        message = "services.woodpecker-server.database.user must match services.woodpecker-server.user if the database is to be automatically provisioned";
      }
    ];

    systemd.services.woodpecker-server = {
      description = "woodpecker-server";
      after = [ "network.target" ] ++ lib.optional usePostgresql "postgresql.service" ++ lib.optional useMysql "mysql.service";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.woodpecker-plugin-git
        pkgs.bash
        pkgs.git
        pkgs.gzip
        pkgs.nixUnstable
      ];
      serviceConfig = mkMerge [
        {
          EnvironmentFile = [ config.lollypops.secrets.files."woodpecker/server-envfile".path ];
          Type = "simple";
          User = cfg.user;
          Group = "woodpecker-server";
          WorkingDirectory = cfg.stateDir;
          Restart = "always";
          # TODO add security/sandbox params.
          ExecStart = "${cfg.package}/bin/woodpecker-server";
        }
      ];
      environment = mkMerge [
        {
          WOODPECKER_OPEN = "true";
          WOODPECKER_ADMIN = cfg.admins;
          WOODPECKER_HOST = cfg.rootUrl;
          WOODPECKER_SERVER_ADDR = "127.0.0.1:${toString cfg.httpPort}";
          WOODPECKER_GRPC_ADDR = "127.0.0.1:${toString cfg.gRPCPort}";
          WOODPECKER_LIMIT_MEM_SWAP = toString cfg.limitSwap;
          WOODPECKER_LIMIT_MEM = toString cfg.limitMem;
          WOODPECKER_LIMIT_CPU_QUOTA = toString cfg.limitCPU;

          # TODO remove
          WOODPECKER_LOG_LEVEL = "debug";
          WOODPECKER_DEBUG_PRETTY = "true";
        }
        (mkIf cfg.useGitea {
          WOODPECKER_GITEA = "true";
          WOODPECKER_GITEA_URL = cfg.giteaUrl;
        })
        (mkIf usePostgresql {
          WOODPECKER_DATABASE_DRIVER = "postgres";
          WOODPECKER_DATABASE_DATASOURCE =
            "postgres://${cfg.database.user}:${cfg.database.password}" +
            "@/${cfg.database.name}" +
            "?host=${if cfg.database.socket != null then cfg.database.socket else cfg.database.host + ":" + toString cfg.database.port}";
        })
        (mkIf (cfg.agentSecretFile != null) {
          WOODPECKER_AGENT_SECRET_FILE = cfg.agentSecretFile;
        })
      ];
    };

    services.postgresql = optionalAttrs (usePostgresql && cfg.database.createDatabase) {
      enable = mkDefault true;

      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions = { "DATABASE ${cfg.database.name}" = "ALL PRIVILEGES"; };
        }
      ];
    };

    services.mysql = optionalAttrs (useMysql && cfg.database.createDatabase) {
      enable = mkDefault true;
      package = mkDefault pkgs.mariadb;

      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensurePermissions = { "${cfg.database.name}.*" = "ALL PRIVILEGES"; };
        }
      ];
    };

    users.users = mkIf (cfg.user == "woodpecker-server") {
      woodpecker-server = {
        createHome = true;
        home = cfg.stateDir;
        useDefaultShell = true;
        group = "woodpecker-server";
        extraGroups = [ "woodpecker" ];
        isSystemUser = true;
      };
    };
    users.groups.woodpecker-server = { };
  };
}
