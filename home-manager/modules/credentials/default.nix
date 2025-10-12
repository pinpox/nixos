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

    accounts.email.maildirBasePath = "Mail";

    programs.aerc = {
      extraConfig.general.unsafe-accounts-conf = true;
      enable = true;
      # stylesets.pinpox = (import ./aerc-style.nix { inherit config;});

      extraConfig = {
        ui = {
          styleset-name = "pinpox";
          icon-attachment = "a ";
          icon-old = "";
          icon-replied = "↩ ";
        };
        compose.address-book-cmd = "carddav-query %s";

        filters = {
          "text/plain" = "colorize";
          "text/calendar" = "calendar";
          "message/delivery-status" = "colorize";
          "message/rfc822" = "colorize";
          #text/html=pandoc -f html -t plain | colorize
          "text/html" = "! html";
          #text/html=! w3m -T text/html -I UTF-8
          #text/*=bat -fP --file-name="$AERC_FILENAME"
          #application/x-sh=bat -fP -l sh
          #image/*=catimg -w $(tput cols) -
          #subject,~Git(hub|lab)=lolcat -f
          #from,thatguywhodoesnothardwraphismessages=wrap -w 100 | colorize
          ".headers" = "colorize";
          "image/*" = "${pkgs.libsixel}/bin/img2sixel - ";
          # image/*=catimg -w$(tput cols) -
        };
      };
    };

    accounts.email.accounts = {
      pablo_tools = {
        folders = {
          # send = "SENT";
          inbox = "INBOX";
        };
        aerc.enable = true;
        address = "mail@pablo.tools";

        aliases = [
          "git@pablo.tools"
          "github@pablo.tools"
          "pablo1@mailbox.org"
        ];

        realName = "Pablo Ovelleiro Corral";
        primary = true;
        maildir.path = "pablo_tools";

        signature = {
          text = ''
            Pablo Ovelleiro Corral

            Web:     https://pablo.tools
            Matrix:  @pinpox:matrix.org
            Github:  https://github.com/pinpox
          '';
          showSignature = "append";
        };

        userName = "pablo1@mailbox.org";
        passwordCommand = "passage show mailbox.org/himalaya";
        imap = {
          host = "imap.mailbox.org";
          tls.enable = true;
        };
        smtp = {
          host = "smtp.mailbox.org";
          port = 465;
        };
      };
    };

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
