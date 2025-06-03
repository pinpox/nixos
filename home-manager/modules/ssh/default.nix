{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.pinpox.programs.ssh;
in
{
  options.pinpox.programs.ssh = {
    enable = mkEnableOption "SSH configuration";
  };

  config = mkIf cfg.enable {
    programs.ssh.enable = true;
    programs.ssh.extraConfig = ''
      PKCS11Provider /run/current-system/sw/lib/libtpm2_pkcs11.so
      CertificateFile ~/.ssh/cert.pub
    '';
  };
}