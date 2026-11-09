{
  config,
  pkgs,
  lib,
  age-plugin-picohsm,
  passage-secret-service,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.yubikey;

  pkcs11Provider = "${pkgs.opensc}/lib/opensc-pkcs11.so";

  # Succeeds once the plugged-in token exposes the key certified in
  # yubikey-ssh-cert.pub. Other smart cards (e.g. a YubiKey only used for
  # age) must not trigger a PIN prompt. pcscd may need a moment to pick up a
  # freshly plugged reader, hence the retries.
  sshTokenPresent = pkgs.writeShellApplication {
    name = "ssh-token-present";
    runtimeInputs = [
      pkgs.openssh
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      want=$(ssh-keygen -lf ${../../home-manager/modules/ssh/yubikey-ssh-cert.pub} | cut -d' ' -f2)
      for _ in 1 2 3 4 5; do
        if ssh-keygen -D ${pkcs11Provider} 2>/dev/null | ssh-keygen -lf - 2>/dev/null | grep -qF " $want "; then
          exit 0
        fi
        sleep 1
      done
      echo "no token with SSH key $want present" >&2
      exit 1
    '';
  };

  # The PIN prompt is noctalia's askpass panel. At login this unit starts
  # together with noctalia, so wait for its IPC before ssh-add asks.
  sshTokenAdd = pkgs.writeShellApplication {
    name = "ssh-token-add";
    runtimeInputs = [
      pkgs.openssh
      pkgs.noctalia
      pkgs.coreutils
    ];
    text = ''
      for _ in $(seq 30); do
        if noctalia msg status >/dev/null 2>&1; then break; fi
        sleep 1
      done
      # Drop a provider left over from a previous plug-in before re-adding.
      ssh-add -e ${pkcs11Provider} 2>/dev/null || true
      exec ssh-add -s ${pkcs11Provider}
    '';
  };
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
      age-plugin-picohsm.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age
      pkgs.rage
      pkgs.age-plugin-yubikey
      pkgs.opensc
      pkgs.keyutils
      pkgs.yubikey-manager
    ];

    environment.sessionVariables = {
      PICOHSM_ASKPASS = "${
        age-plugin-picohsm.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/picohsm-askpass";
      PICOHSM_ASKPASS_BACKEND = lib.getExe pkgs.noctalia-askpass;
      # rage prompts for age plugin PINs (age-plugin-yubikey) via pinentry.
      PINENTRY_PROGRAM = "${pkgs.noctalia-askpass}/bin/pinentry-noctalia";
      # Several YubiKeys hold the same age identity, so ~/.config/age/identities
      # lists one stub per key. Skip the ones that are not plugged in instead of
      # prompting for them; the prompt loop hangs forever under clan/passage,
      # which capture the plugin's stdio. Needs the overlay patch.
      AGE_PLUGIN_YUBIKEY_SKIP_NOT_FOUND = "1";
      # passage delegates to the binary named here; rage honors
      # PINENTRY_PROGRAM, the Go age only prompts on a TTY.
      PASSAGE_AGE = "rage";
    };

    security.tpm2.enable = true;
    security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
    security.tpm2.pkcs11.package = pkgs.tpm2-pkcs11-esapi;
    security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
    users.users.pinpox.extraGroups = [ config.security.tpm2.tssGroup ]; # tss group has access to TPM devices

    programs.ssh.startAgent = true;
    # OpenSSH 10.2+ uses comma-separated list (not colon) for -P whitelist
    programs.ssh.agentPKCS11Whitelist = "${config.security.tpm2.pkcs11.package}/lib/libtpm2_pkcs11.so,${pkcs11Provider}";

    # ssh-agent logs in to the token once, at `ssh-add -s`, and keeps that
    # PKCS#11 session forever. Once the token is unplugged the session is gone
    # (C_Sign fails with CKR_TOKEN_NOT_PRESENT) and ssh-agent never reopens it
    # or asks for the PIN again. So follow the token instead: smartcard.target
    # is reached when a CCID reader appears and stopped when the last one is
    # removed (StopWhenUnneeded), which loads the key with a PIN prompt on
    # plug-in and drops it on removal. graphical-session.target covers a token
    # that is already plugged in at login; Requisite keeps the smartcard.target
    # trigger that fires before the graphical session exists from prompting.
    systemd.user.services.ssh-agent-pkcs11 = {
      description = "Load the hardware token's SSH key into ssh-agent";
      wantedBy = [
        "smartcard.target"
        "graphical-session.target"
      ];
      partOf = [
        "smartcard.target"
        "graphical-session.target"
      ];
      requisite = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        "ssh-agent.service"
      ];
      requires = [ "ssh-agent.service" ];
      environment = {
        SSH_AUTH_SOCK = "%t/ssh-agent";
        SSH_ASKPASS = lib.getExe pkgs.noctalia-askpass;
        SSH_ASKPASS_REQUIRE = "force";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecCondition = lib.getExe sshTokenPresent;
        ExecStart = lib.getExe sshTokenAdd;
        ExecStop = "-${pkgs.openssh}/bin/ssh-add -e ${pkcs11Provider}";
      };
    };

    # services.yubikey-agent.enable = false;
    services.udev.packages = [ pkgs.yubikey-personalization ];

    systemd.user.services.passage-secret-service = {
      description = "passage-backed D-Bus Secret Service";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart =
          lib.getExe
            passage-secret-service.packages.${pkgs.stdenv.hostPlatform.system}.passage-secret-service;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
