{
  lib,
  config,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.sbox;
in
{
  imports = [ flake-self.inputs.sbox.homeManagerModules.sbox ];

  options.pinpox.programs.sbox.enable = mkEnableOption "sbox bubblewrap sandbox wrapper";

  config = mkIf cfg.enable {
    programs.sbox = {
      enable = true;

      # Editable working copy of all my projects.
      bind."$HOME/code" = { };

      # Config carried read-only into every sandbox.
      bindReadOnly = {
        "$HOME/.omp" = { };
        "$HOME/.claude/CLAUDE.md" = { };
        "$HOME/.config/zsh" = { }; # ZDOTDIR
      };
    };
  };
}
