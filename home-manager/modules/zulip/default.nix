{
  lib,
  pkgs,
  config,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.zulip;
  zulip = flake-self.inputs.skill-collection.packages.${pkgs.stdenv.hostPlatform.system}.zulip;
in
{
  options.pinpox.programs.zulip = {
    enable = mkEnableOption "zulip CLI";

    passageEntry = mkOption {
      type = types.str;
      default = "clan-vars/per-machine/kfbox/zulip-nats-integrations/zuliprc";
      description = ''
        Passage entry holding the `.zuliprc` (the `[api]` block: email, key,
        site). `zulip` decrypts it on demand via `passage show`, so the personal
        API key never lands in a plaintext dotfile or in the store.

        Defaults to the same entry the kfbox `zulip-bridge` clan service uses —
        one key, one place to rotate it.
      '';
    };
  };

  config = mkIf cfg.enable {

    # Ships bin/zulip and share/skills/zulip in one derivation.
    home.packages = [ zulip ];
    pinpox.agentSkills = [ zulip ];

    # zsh gets its own copy: it does not source home-manager's session
    # variables (same reason the credentials module sets both).
    home.sessionVariables.ZULIP_PASSAGE_ENTRY = cfg.passageEntry;
    programs.zsh.sessionVariables.ZULIP_PASSAGE_ENTRY = cfg.passageEntry;
  };
}
