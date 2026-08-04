{
  pkgs,
  config,
  lib,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.claude-code;
in
{
  options.pinpox.programs.claude-code = {
    enable = mkEnableOption "claude-code";

    skills = mkOption {
      type = types.listOf types.package;
      default = config.pinpox.agentSkills;
      defaultText = literalExpression "config.pinpox.agentSkills";
      description = ''
        Agent Skill packages to make available to Claude Code, each shipping its
        skill at `$out/share/skills/<name>/SKILL.md`. Linked into
        `~/.claude/skills/<name>`.

        Defaults to every skill in `pinpox.agentSkills`; set it explicitly to
        give Claude Code a different set than the other harnesses.
      '';
      example = literalExpression "[ pkgs.agentSkills.todos ]";
    };
  };

  config = mkIf cfg.enable {

    home.packages = [
      pkgs.claude-code
    ];

    home.file = pinpox-utils.mkSkillLinks ".claude/skills" cfg.skills // {

      # Declarative settings via settings.local.json (merged with mutable settings.json)
      ".claude/settings.local.json".text = builtins.toJSON {
        permissions.allow = [
          "Bash(incus:*)"
          "Read(/tmp/**)"
        ];
      };
    };
  };
}
