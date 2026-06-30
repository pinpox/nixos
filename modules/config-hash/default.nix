{
  config,
  lib,
  flake-self,
  ...
}:
let
  cfg = config.pinpox.configHash;
  host = config.networking.hostName;
in
{
  options.pinpox.configHash.enable =
    lib.mkEnableOption "embedding the pure per-host config hash into the system closure"
    // {
      default = true;
    };

  # Write this host's stamp-stripped ("pure") toplevel hash into the closure so
  # it can be read at runtime (/run/current-system/config-hash) and compared
  # against what the repo currently evaluates to — regardless of whether the
  # deploy was from a clean or dirty tree. The value comes from the flake's
  # `configHashes` output, which strips the whole-flake couplings AND disables
  # this writer (pinpox.configHash.enable = false), so the computation never
  # reads itself.
  config = lib.mkIf cfg.enable {
    system.systemBuilderCommands = ''
      echo -n ${lib.escapeShellArg (flake-self.configHashes.${host} or "")} > $out/config-hash
    '';
  };
}
