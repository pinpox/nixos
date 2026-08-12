{ lib, ... }:
{
  # Harness-agnostic registry of Agent Skill packages. Any module can contribute
  # a skill next to the tool it documents (e.g. the vja module adds `todos`) and
  # every enabled agent harness picks it up, because the harness modules default
  # their own `skills` option to this list.
  #
  # Each entry must ship its skill at `$out/share/skills/<name>/SKILL.md` — use
  # `pkgs.agentSkills.<name>` for skills in this repo's `./skills`, or
  # `pkgs.mkAgentSkill` / a third-party skill package for anything else.
  options.pinpox.agentSkills = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Agent Skill packages offered to every enabled agent harness.";
    example = lib.literalExpression "[ pkgs.agentSkills.nats ]";
  };
}
