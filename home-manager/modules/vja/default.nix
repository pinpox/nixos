{
  lib,
  pkgs,
  config,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.vja;
in
{
  options.pinpox.programs.vja.enable = mkEnableOption "vja Vikunja CLI";

  config = mkIf cfg.enable {

    home.packages = [ pkgs.vja ];

    xdg = {
      enable = true;

      # vja only reads this file; the auth token lives beside it in
      # ~/.config/vja/token.json and stays mutable.
      configFile."vja/config.rc".text = ''
        [application]
        frontend_url=https://todo.pablo.tools
        api_url=https://todo.pablo.tools/api/v1

        [output]
        # Use with: vja ls --custom-format=simple
        simple={x.id:5} {x.title:40.40} {x.project.title:15.15} {x.assignees:15.15} {x.due_date.strftime("%a %d.%m %H:%M") if x.due_date else "":15.15}
      '';
    };

    # Agent skill documenting this CLI (repo is the source of truth).
    home.file.".claude/skills/todos/SKILL.md".source = "${flake-self}/skills/todos/SKILL.md";
  };
}
