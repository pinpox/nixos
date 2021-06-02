{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
  # Email
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
      notmuch.enable = false;

      folders = {
        # TODO
        drafts = "";
      };

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
      imap = { host = "imap.mailbox.org"; };
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
}
