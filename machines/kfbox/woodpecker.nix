{ config, attic, pkgs, lib, flake-pipeliner, ... }: {

  imports = [
    flake-pipeliner.nixosModules.flake-pipeliner
    attic.nixosModules.atticd
  ];

  lollypops.secrets.files."attic/envfile" = { };

  services.atticd = {
    enable = true;

    # Secrets:
    # ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64="output from openssl"
    # openssl rand 64 | base64 -w0
    credentialsFile = config.lollypops.secrets.files."attic/envfile".path;

    settings = {
      listen = "127.0.0.1:7373";

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };



  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts."build.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:8000";
  };

  # systemd.services.woodpecker-server = {
  #   serviceConfig = {
  #     # Set username for DB access
  #     User = "woodpecker";
  #   };
  # };

  # Server
  lollypops.secrets.files."woodpecker/server" = { };
  services.woodpecker-server = {
    enable = true;

    # Secrets in env file: WOODPECKER_GITHUB_CLIENT, WOODPECKER_GITHUB_SECRET,
    # WOODPECKER_AGENT_SECRET, WOODPECKER_PROMETHEUS_AUTH_TOKEN
    environmentFile = config.lollypops.secrets.files."woodpecker/server".path;

    environment = {
      WOODPECKER_HOST = "https://build.0cx.de";
      WOODPECKER_OPEN = "false";
      WOODPECKER_GITHUB = "true";
      WOODPECKER_ADMIN = "pinpox"; # Add multiple users as "user1,user2"
      WOODPECKER_ORGS = "lounge-rocks";
      WOODPECKER_CONFIG_SERVICE_ENDPOINT = "http://127.0.0.1:8585";
    };
  };

  # Agents
  lollypops.secrets.files."woodpecker/agent" = { };
  services.woodpecker-agents.agents = {
    exec = {
      enable = true;
      # Secrets in envfile: WOODPECKER_AGENT_SECRET
      environmentFile = [ config.lollypops.secrets.files."woodpecker/agent".path ];
      environment = {
        WOODPECKER_BACKEND = "local";
        WOODPECKER_SERVER = "localhost:9000";
        WOODPECKER_MAX_WORKFLOWS = "10";
        WOODPECKER_FILTER_LABELS = "type=exec";
        WOODPECKER_HEALTHCHECK = "false";
        NIX_REMOTE = "daemon";
        PAGER = "cat";
      };
    };
  };


  # Adjust runner service for nix usage
  systemd.services.woodpecker-agent-exec = {

    serviceConfig = {
      # Same option as upstream, without @setuid
      SystemCallFilter = lib.mkForce "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @swap";

      User = "woodpecker-agent";

      BindPaths = [
        "/nix/var/nix/daemon-socket/socket"
        "/run/nscd/socket"
      ];
      BindReadOnlyPaths = [
        "/etc/passwd:/etc/passwd"
        "/etc/group:/etc/group"
        "/etc/nix:/etc/nix"
        "${config.environment.etc."ssh/ssh_known_hosts".source}:/etc/ssh/ssh_known_hosts"
        "/etc/machine-id"
        # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
        "/nix/"
      ];
    };

    path = with pkgs; [
      woodpecker-plugin-git
      bash
      coreutils
      git
      git-lfs
      gnutar
      gzip
      nix
    ];
  };

  # Allow user to run nix
  nix.settings.allowed-users = [ "woodpecker-agent" ];

  # Pipeliner
  services.flake-pipeliner = {
    enable = true;
    environment = {

      PIPELINER_PUBLIC_KEY_FILE = "${./woodpecker-public-key}";
      PIPELINER_HOST = "localhost:8585";
      PIPELINER_OVERRIDE_FILTER = "test-*";
      PIPELINER_SKIP_VERIFY = "false";
      PIPELINER_FLAKE_OUTPUT = "woodpecker-pipeline";
      PIPELINER_DEBUG = "true";
      NIX_REMOTE = "daemon";
      PRE_CMD = "git -v";
      PAGER = "cat";
    };
  };
}
