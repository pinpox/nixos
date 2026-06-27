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
}
