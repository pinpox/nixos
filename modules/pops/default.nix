{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pops;

  secret-file = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = config._module.args.name;
        description = "Name of the secret";
      };

      cmd = mkOption {
        type = types.str;
        default = "cat ${config.source-path}";
        description = "TODO";
      };

      path = mkOption {
        type = types.str;
        default = "/run/keys/${config.name}";
        description = "Path to place the secret file";
      };
      mode = mkOption {
        type = types.str;
        default = "0400";
        description = "Unix permission";
      };
      owner = mkOption {
        type = types.str;
        default = "root";
        description = "Owner of the file";
      };
      group-name = mkOption {
        type = types.str;
        default = "root";
        description = "Group of the file";
      };
      source-path = mkOption {
        type = types.str;
        default = "/var/src/secrets/${config.name}";
        description = "Source to copy from";
      };
    };
  });
in
{

  options.pops = {
    secrets = {
      files = mkOption {
        type = with types; attrsOf secret-file;
        default = { };
        description = "Attribute set specifying secrets to be deployed";
      };
    };


    deployment = {
      host = mkOption {
        type = types.str;
        default = "${config.networking.hostName}";
        description = "Host to deploy to";
      };
      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to deploy as";
      };
    };
  };
  # config = { };
}
