{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.credentials;
in
{
  options.pinpox.defaults.credentials.enable = mkEnableOption "credentials defaults";

  config = mkIf cfg.enable {
    # Email

    accounts.email.maildirBasePath = "Mail";

    programs.neomutt = {
      enable = true;
      sidebar = { enable = true; };
      extraConfig = ''
        set imap_user = "pablo1@mailbox.org"
        set imap_pass = "`pass mailbox.org/pablo1@mailbox.org`"
      '';
    };

    accounts.email.accounts = {
      pablo_tools = {
        address = "mail@pablo.tools";
        realName = "Pablo Ovelleiro Corral";
        primary = true;
        gpg = {
          key = "D03B218CAE771F77D7F920D9823A6154426408D3";
          signByDefault = true;
        };
        mbsync.enable = false;
        msmtp.enable = false;
        # notmuch.enable = false;
        neomutt = {
          enable = true;
          mailboxName = "pablo_tools";
          # extraConfig = '''';
        };

        maildir = { path = "pablo_tools"; };
        # himalaya.enable = true;

        # folders = {
        #   # TODO
        #   drafts = "";
        # };

        signature = {
          text = ''
            Pablo Ovelleiro Corral

            Web:     https://pablo.tools
            XMPP:    pablo1@mailbox.org
            GPG-Key: https://pablo.tools/gpg-key
          '';
          showSignature = "append";
        };

        userName = "pablo1@mailbox.org";
        passwordCommand = "pass mailbox.org/pablo1@mailbox.org";
        imap = {
          host = "imap.mailbox.org";
          tls.enbale = true;
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

    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
}
