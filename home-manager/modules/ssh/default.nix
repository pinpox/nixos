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

      enableDefaultConfig = false;

      matchBlocks = {

        "*" = {
          extraOptions = {
            ForwardAgent = "no";
            ServerAliveInterval = "0";
            ServerAliveCountMax = "3";
            Compression = "no";
            AddKeysToAgent = "yes";
            HashKnownHosts = "no";
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
            PKCS11Provider = "/run/current-system/sw/lib/opensc-pkcs11.so";
            # CertificateFile = "~/.ssh/cert.pub";
            CertificateFile = "${./ssh-key-cert.pub}";
          };
        };

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
