{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.crit;
in
{
  options.pinpox.programs.crit.enable = mkEnableOption "crit, local-first review tool for agent plans and diffs";

  config = mkIf cfg.enable {

    home.packages = [ pkgs.crit ];

    # crit ships its skills per harness (integrations/<harness>/skills), written
    # against that harness's tools, so they can't go into the shared
    # pinpox.agentSkills. Taken from the package's own source so the skills
    # always match the installed CLI.
    home.file = mkIf config.pinpox.programs.omp.enable (
      genAttrs' [ "crit" "crit-cli" "crit-story" ] (
        name:
        nameValuePair ".omp/agent/skills/${name}" {
          source = "${pkgs.crit.src}/integrations/omp/skills/${name}";
        }
      )
    );
  };
}
