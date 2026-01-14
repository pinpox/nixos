{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.credentials;
in
{
  options.pinpox.defaults.credentials.enable = mkEnableOption "credentials defaults";

  config = mkIf cfg.enable {

    # Set up passage store directory with remote configured (but not cloned)
    # On a fresh machine, just run: passage git pull
    home.activation.setupPassageStore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      STORE_DIR="${config.home.homeDirectory}/.passage/store"
      if [ ! -d "$STORE_DIR/.git" ]; then
        run mkdir -p "$STORE_DIR"
        run ${pkgs.git}/bin/git -C "$STORE_DIR" init -b master
        run ${pkgs.git}/bin/git -C "$STORE_DIR" remote add origin "gitea@git.0cx.de:pinpox/passage.git"
        run ${pkgs.git}/bin/git -C "$STORE_DIR" config branch.master.remote origin
        run ${pkgs.git}/bin/git -C "$STORE_DIR" config branch.master.merge refs/heads/master
      fi
    '';

    # List of public keys (recipients) to encrypt to.
    # Use `age-plugin-picohsm --list` to get the HSM key if needed. The second
    # key is an offline last-resort backup key
    home.sessionVariables.PASSAGE_RECIPIENTS_FILE = "${./age-recipients}";

    # The file ~/.config/age/identities still needs to be generated.
    # Run `age-plugin-picohsm -list` and put the age-key identity
    # (AGE-PLUGIN-PICOHSM-XXXXX) into the file
    programs.zsh.sessionVariables.PASSAGE_IDENTITIES_FILE = "$HOME/.config/age/identities";

    # The nixos agent is better
    services.ssh-agent.enable = false;
  };
}
