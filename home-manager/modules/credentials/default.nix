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

    # Passage recipients (public keys for encryption)
    home.file.".passage/.age-recipients".text = ''
      age15m0pgtr06pqaql2wx8e2xqupcctzkf0dk0cc06hv3cjcgpe5u3ns59jaun
      age1picohsm1qjpqjd9pnlh8zem6wwz62ml9z995fsdz9e23dumamjj0nl4cq0m5dx5v5mm5njelm3hmv4w3mfs5mzvks3xtu6k723jr0am49hrk9mduxvxpps
    '';

    # The file ~/.config/age/identities still needs to be generated.
    # Run `age-plugin-picohsm -list` and put the age-key identity
    # (AGE-PLUGIN-PICOHSM-XXXXX) into the file
    programs.zsh.sessionVariables.PASSAGE_IDENTITIES_FILE = "$HOME/.config/age/identities";
    home.sessionVariables.PASSAGE_IDENTITIES_FILE = "$HOME/.config/age/identities";

    # The nixos agent is better
    services.ssh-agent.enable = false;
  };
}
