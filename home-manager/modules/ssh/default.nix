{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.pinpox.programs.ssh;
in
{
  options.pinpox.programs.ssh.enable = mkEnableOption "SSH configuration";

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      ssh.enableDefaultConfig = false;

      extraConfig = ''
        PKCS11Provider /run/current-system/sw/lib/libtpm2_pkcs11.so
        CertificateFile ~/.ssh/cert.pub
      '';

      matchBlocks = {
        "ap-oben" = {
          hostname = "UAP-ProOBEN.lan";
          user = "pinpox";
          extraOptions = {
            PubkeyAcceptedAlgorithms = "+ssh-rsa";
            HostkeyAlgorithms = "+ssh-rsa";
          };
        };
        "ap-mitte" = {
          hostname = "UAP-ProMITTE.lan";
          user = "pinpox";
          extraOptions = {
            PubkeyAcceptedAlgorithms = "+ssh-rsa";
            HostkeyAlgorithms = "+ssh-rsa";
          };
        };
        "ap-unten" = {
          hostname = "UAP-ProUNTEN.lan";
          user = "pinpox";
          extraOptions = {
            PubkeyAcceptedAlgorithms = "+ssh-rsa";
            HostkeyAlgorithms = "+ssh-rsa";
          };
        };
      };
    };
  };
}
