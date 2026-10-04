{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.email;
in
{
  options.pinpox.defaults.email.enable = mkEnableOption "email client config";

  config = mkIf cfg.enable {

    accounts.email.maildirBasePath = "Mail";

    programs.himalaya.enable = true;

    # home-manager's himalaya module still emits the v1 schema, which himalaya
    # 2.0 rejects ("No backend matching `auto` is configured"). Generate the v2
    # layout instead, derived from the account below.
    xdg.configFile."himalaya/config.toml".source =
      let
        acc = config.accounts.email.accounts.pablo_tools;
        sasl.plain = {
          username = acc.userName;
          password.command = acc.passwordCommand;
        };
      in
      mkForce (
        (pkgs.formats.toml { }).generate "himalaya-config.toml" {
          downloads-dir = "${config.home.homeDirectory}/Downloads";
          mailbox.alias = {
            inbox = "INBOX";
            sent = "Sent";
            drafts = "Drafts";
            trash = "Trash";
          };
          accounts.pablo_tools = {
            default = true;
            imap = {
              server = "imaps://${acc.imap.host}:${toString acc.imap.port}";
              inherit sasl;
            };
            smtp = {
              server = "smtps://${acc.smtp.host}:${toString acc.smtp.port}";
              inherit sasl;
            };
          };
        }
      );

    programs.aerc = {
      extraConfig.general.unsafe-accounts-conf = true;
      enable = true;
      # stylesets.pinpox = (import ./aerc-style.nix { inherit config;});

      extraConfig = {
        ui = {
          # styleset-name = "pinpox";
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
        himalaya.enable = true;
        address = "mail@pablo.tools";

        aliases = [
          "git@pablo.tools"
          "mail@pinpox.com"
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
          port = 993;
          tls.enable = true;
          authentication = "plain";
        };
        smtp = {
          host = "smtp.mailbox.org";
          port = 465;
          authentication = "plain";
        };
      };
    };
  };
}
