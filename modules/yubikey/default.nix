{
  config,
  pkgs,
  lib,
  age-plugin-picohsm,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.yubikey;
in
{

  options.pinpox.defaults.yubikey.enable = mkEnableOption "yubikey defaults";

  config = mkIf cfg.enable {

    # OpenSC PIN caching (per process)
    # environment.etc."opensc.conf".text = ''
    #   app default {
    #     framework pkcs15 {
    #       use_pin_caching = true;
    #       pin_cache_counter = 10;
    #       pin_cache_ignore_user_consent = true;
    #     }
    #   }
    # '';

  services.pcscd.enable = true;


  # Allow pcscd access for SSH sessions (not just graphical)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.debian.pcsc-lite.access_pcsc" ||
          action.id == "org.debian.pcsc-lite.access_card") {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = [
    age-plugin-picohsm.packages.${pkgs.system}.default
    pkgs.age
    pkgs.opensc
  ];


    security.tpm2.enable = true;
    security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
    security.tpm2.pkcs11.package = pkgs.tpm2-pkcs11-esapi;
    security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
    users.users.pinpox.extraGroups = [ config.security.tpm2.tssGroup ]; # tss group has access to TPM devices

    programs.ssh.startAgent = true;
    # OpenSSH 10.2+ uses comma-separated list (not colon) for -P whitelist
    programs.ssh.agentPKCS11Whitelist = "${config.security.tpm2.pkcs11.package}/lib/libtpm2_pkcs11.so,${pkgs.opensc}/lib/opensc-pkcs11.so";

    # services.yubikey-agent.enable = false;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
