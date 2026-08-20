{
  lib,
  pkgs,
  config,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.tea;
in
{
  options.pinpox.programs.tea.enable = mkEnableOption "tea Gitea CLI";

  config = mkIf cfg.enable {

    home.packages = [ pkgs.tea ];

    # ~/.config/tea/config.yml holds one login (URL + API token) per Gitea
    # instance and stays mutable: `tea logins add` writes tokens there, so it
    # cannot be a store symlink.

    # Agent skill documenting this CLI, offered to every enabled harness.
    pinpox.agentSkills = [
      flake-self.inputs.skill-collection.packages.${pkgs.stdenv.hostPlatform.system}.gitea
    ];
  };
}
