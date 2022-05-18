# Taken from https://raw.githubusercontent.com/Mic92/dotfiles/23f163cae52545d44a7e379dc204010b013d679a/nixos/vms/modules/secrets.nix
{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.krops.secrets;
  secret-file = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = config._module.args.name;
        description = "Name of the secret";
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
  options.krops.secrets = {
    files = mkOption {
      type = with types; attrsOf secret-file;
      default = { };
      description = "Attribute set specifying secrets to be deployed";
    };
  };
  config = lib.mkIf (cfg.files != { }) {
    system.activationScripts.setup-secrets =
      let
        files =
          unique (map (flip removeAttrs [ "_module" ]) (attrValues cfg.files));
        script = ''
          echo setting up secrets...
          mkdir -p /run/keys -m 0750
          chown root:keys /run/keys
          ${concatMapStringsSep "\n" (file: ''
              ${pkgs.coreutils}/bin/install \
                -D \
                --compare \
                --verbose \
                --mode=${lib.escapeShellArg file.mode} \
                --owner=${lib.escapeShellArg file.owner} \
                --group=${lib.escapeShellArg file.group-name} \
                ${lib.escapeShellArg file.source-path} \
                ${lib.escapeShellArg file.path} \
              || echo "failed to copy ${file.source-path} to ${file.path}"
            '')
            files}
        '';
      in
      stringAfter [ "users" "groups" ]
        "source ${pkgs.writeText "setup-secrets.sh" script}";
  };
}
