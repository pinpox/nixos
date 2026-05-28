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

      settings = {

        "*" = {
          CertificateFile = [ "${./yubikey-ssh-cert.pub}" ];
          ForwardAgent = "no";
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          Compression = "no";
          AddKeysToAgent = "yes";
          HashKnownHosts = "no";
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "1h";
          PKCS11Provider = "/run/current-system/sw/lib/opensc-pkcs11.so";
        };

        "ap-oben" = {
          HostName = "UAP-ProOBEN.lan";
          User = "pinpox";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
          HostkeyAlgorithms = "+ssh-rsa";
        };
        "ap-mitte" = {
          HostName = "UAP-ProMITTE.lan";
          User = "pinpox";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
          HostkeyAlgorithms = "+ssh-rsa";
        };
        "ap-unten" = {
          HostName = "UAP-ProUNTEN.lan";
          User = "pinpox";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
          HostkeyAlgorithms = "+ssh-rsa";
        };
      };
    };
  };
}
