{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.yubikey;
in
{

  options.pinpox.defaults.yubikey.enable = mkEnableOption "yubikey defaults";

  config = mkIf cfg.enable {

    security.tpm2.enable = true;
    security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
    security.tpm2.pkcs11.package = pkgs.tpm2-pkcs11-esapi;
    security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
    users.users.pinpox.extraGroups = [ config.security.tpm2.tssGroup ]; # tss group has access to TPM devices

    programs.ssh.startAgent = true;
    programs.ssh.agentPKCS11Whitelist = "${config.security.tpm2.pkcs11.package}/lib/*";

    # services.yubikey-agent.enable = false;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
