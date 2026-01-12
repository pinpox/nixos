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

    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };

    # The nixos agent is better
    services.ssh-agent.enable = false;

    home.packages = with pkgs; [
      tpm2-tools # To work with the TPM
    ];
  };
}
