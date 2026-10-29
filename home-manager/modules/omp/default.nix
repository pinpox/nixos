{
  lib,
  pkgs,
  config,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.omp;

  # Appended (not prepended) to PATH, so tools from the calling shell or a
  # project devshell still take precedence over these fallbacks.
  wrapped =
    if cfg.extraPackages == [ ] then
      cfg.package
    else
      pkgs.symlinkJoin {
        name = "${cfg.package.name}-wrapped";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/omp --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
        '';
        inherit (cfg.package) meta;
      };
in
{
  options.pinpox.programs.omp = {

    enable = mkEnableOption "omp (Oh My Pi) coding agent";

    package = mkOption {
      type = types.package;
      default = pkgs.omp;
      defaultText = literalExpression "pkgs.omp";
      description = "The omp package to install.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.python3 pkgs.gh ]";
      description = ''
        Packages whose `bin/` is appended to omp's PATH (and thus to every
        command it runs) without installing them into the user profile.
      '';
    };

    skills = mkOption {
      type = types.listOf types.package;
      default = config.pinpox.agentSkills;
      defaultText = literalExpression "config.pinpox.agentSkills";
      description = ''
        Agent Skill packages to make available to omp, each shipping its skill
        at `$out/share/skills/<name>/SKILL.md`.

        Linked into `~/.omp/agent/skills/<name>`, omp's user-level `native`
        skill root — the highest-precedence provider, so these win over
        same-named skills discovered from `~/.claude`, `~/.codex` or autolearn.

        Defaults to every skill in `pinpox.agentSkills`; set it explicitly to
        give omp a different set than the other harnesses.
      '';
      example = literalExpression "[ inputs.skill-collection.packages.\${system}.hedgedoc ]";
    };
  };

  config = mkIf cfg.enable {

    home.packages = [ wrapped ];

    # `~/.omp/agent/{config,models}.yml` are deliberately left mutable: omp
    # writes to them itself (setupVersion, autoqa consent, model roles picked in
    # the TUI), so a read-only store symlink would break onboarding.
    home.file = pinpox-utils.mkSkillLinks ".omp/agent/skills" cfg.skills;
  };
}
