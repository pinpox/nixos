{ pkgs, ... }:
{

  mkEnvGenerator = envs: rec {
    files.envfile = { };
    runtimeInputs = [ pkgs.coreutils ];
    prompts = pkgs.lib.genAttrs envs (name: {
      persist = false;
    });

    # Invalidate on env change
    validation.script = script;

    script = ''
      mkdir -p $out
      cat <<EOT >> $out/envfile
      ${builtins.concatStringsSep "\n" (map (e: "${e}='$(cat $prompts/${e})'") envs)}
      EOT
    '';
  };

  # Shared per-account Matrix password (clan share = true): the matrix reconciler
  # creates the account with it, opencrow logs in with it — same value on both
  # the homeserver host and the bot host.
  mkMatrixPassword = {
    share = true;
    files."password" = { };
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssl
    ];
    script = ''printf '%s' "$(openssl rand -hex 32)" > "$out/password"'';
  };

  # p0 inference API key, prompted once per machine and persisted. The prompt
  # itself becomes the `api-key` file (raw token); `env` is a systemd
  # EnvironmentFile (P0_API_KEY=…) for consumers taking `environmentFiles`.
  # traube declares its own prompt-only `p0-inference-key` (hermes reads the
  # raw file as a credential, no env file) — per-machine, so shapes may differ.
  mkP0Key = {
    files."env" = { };
    prompts."api-key" = {
      type = "hidden";
      persist = true;
      description = "p0 inference API key (https://inference.p0.contact)";
    };
    script = ''
      printf 'P0_API_KEY=%s\n' "$(cat "$prompts"/api-key)" > "$out/env"
    '';
  };

  renderMustache =
    name: template: data:
    # Render handlebars `template` called `name` by converting `data` to JSON
    pkgs.stdenv.mkDerivation {

      name = "${name}";

      # Disable phases which are not needed. In particular the unpackPhase will
      # fail, if no src attribute is set
      nativeBuildInpts = [ pkgs.mustache-go ];

      # Pass Json as file to avoid escaping
      passAsFile = [ "jsonData" ];
      jsonData = builtins.toJSON data;

      phases = [
        "buildPhase"
        "installPhase"
      ];

      buildPhase = ''
        ${pkgs.mustache-go}/bin/mustache $jsonDataPath ${template} > rendered_file
      '';
      installPhase = ''
        cp rendered_file $out
      '';
    };

  # home.file entries linking each Agent Skill package into one harness's skill
  # root, e.g. `mkSkillLinks ".omp/agent/skills" [ skill-collection.hedgedoc ]`.
  # Each package ships its skill at `$out/share/skills/<name>/`; the name comes
  # from `passthru.skillName` (or `pname`) so no store path has to be read at
  # eval time.
  mkSkillLinks =
    dir: skills:
    builtins.listToAttrs (
      map (
        skill:
        let
          name = skill.skillName or skill.pname;
        in
        {
          name = "${dir}/${name}";
          value.source = "${skill}/share/skills/${name}";
        }
      ) skills
    );
}
