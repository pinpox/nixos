{ config, pkgs, lib, flake-pipeliner, ... }: {

  imports = [
    flake-pipeliner.nixosModules.flake-pipeliner
  ];

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
