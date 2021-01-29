{ config, pkgs, lib, ... }: {

  # TODO sumbit a PR to allow for a environmentfile

  # The service packaged in nixpkgs places tokens and other sensitive
  # information in the nix store and doesn't yet allow to specify envfiles for
  # the systemd service. Placing the secerts here is not possible, as this
  # config will be public on GitHub.

  # Create system user and group
  users.groups."hedgedoc" = { };
  users.users."hedgedoc" = {
    description = "HedgeDoc service user";
    group = "hedgedoc";
    extraGroups = [ ];
    home = "/var/lib/hedgedoc";
    createHome = true;
    isSystemUser = true;
  };

  systemd.services.hedgedoc = {
    description = "HedgeDoc Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" ];
    serviceConfig = {
      WorkingDirectory = "/var/lib/hedgedoc";
      ExecStart = "${pkgs.hedgedoc}/bin/hedgedoc";
      EnvironmentFile = /var/src/secrets/hedgedoc/envfile;

      # TODO Extract non-secrets from envfile and put them here instead
      # Environment = [
      #   "CMD_CONFIG_FILE=SOME_PATH"
      #   "NODE_ENV=production"
      # ];

      Restart = "always";
      User = "hedgedoc";
      Group = "hedgedoc";
      PrivateTmp = true;
    };
  };
}
