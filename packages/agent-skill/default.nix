{ runCommand }:

# Package one Agent Skill (SKILL.md + assets) in the standard layout:
#
#   $out/share/skills/<name>/SKILL.md
#
# That path is the interchange format between skill producers and agent
# harnesses: anything shipping it can be consumed by the omp/claude-code
# home-manager modules (see utils/default.nix `mkSkillLinks`), and it is the
# same convention third-party skill flakes like mics-skills already use.
#
# `passthru.skillName` lets consumers resolve the skill directory without
# reading the store path (which would force the derivation at eval time).
{
  name,
  src,
  meta ? { },
}:

runCommand "agent-skill-${name}"
  {
    inherit src;
    passthru.skillName = name;
    meta = {
      description = "Agent skill: ${name}";
    }
    // meta;
  }
  ''
    if [ ! -f "$src/SKILL.md" ]; then
      echo "agent-skill ${name}: $src/SKILL.md does not exist" >&2
      exit 1
    fi

    # The frontmatter name is what the harness shows the model; keep it in sync
    # with the directory name so a rename can't silently split the two.
    declared=$(sed -n '2,/^---$/{s/^name:[[:space:]]*//p}' "$src/SKILL.md" | head -1)
    if [ "$declared" != "${name}" ]; then
      echo "agent-skill ${name}: SKILL.md declares name '$declared'" >&2
      exit 1
    fi

    mkdir -p "$out/share/skills"
    cp -r "$src" "$out/share/skills/${name}"
  ''
