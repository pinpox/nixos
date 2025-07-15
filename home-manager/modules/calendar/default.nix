{
  config,
  lib,
  pkgs,
  flake-inputs,
  ...
}:

with lib;

let
  cfg = config.pinpox.defaults.calendar;
in
{
  options.pinpox.defaults.calendar.enable = mkEnableOption "Calendar config";

  config = mkIf cfg.enable {

    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    programs.khal.enable = true;
    programs.khal.settings = {

      default.default_calendar = "Kalender";

      # view = {
      #   agenda_event_format = "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{reset}";
      # };
    };

    programs.khard.enable = true;
    programs.khard.package = flake-inputs.khard.packages."x86_64-linux".default;

    # khard.settings is broken, it does not support subsections, so we write
    # the file directly
    xdg.configFile."khard/khard.conf".source = pkgs.writeTextFile {
      name = "khard.conf";
      text = ''
        [addressbooks]
        [[mailbox]]
        path = ~/.local/share/office/contacts/mailbox/*
        type = discover

        [[gmail]]
        path = ~/.local/share/office/contacts/gmail/*
        type = discover

        [[nextcloud]]
        path = ~/.local/share/office/contacts/nextcloud/*
        type = discover

        [general]
        debug = no
        default_action = list
        # These are either strings or comma seperated lists
        editor = nvim, -i, NONE
        merge_editor = nvim, -d
      '';
    };

    accounts.contact.accounts = {

      "nextcloud" = {
        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];

          userNameCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-nextcloud-user"
          ];
        };
        remote = {
          type = "carddav";
          url = "https://files.pablo.tools";
          passwordCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-nextcloud"
          ];
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/contacts/nextcloud";
        };
      };

      "mailbox" = {
        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];

          userNameCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-mailbox-user"
          ];
        };
        remote = {
          type = "carddav";
          url = "https://dav.mailbox.org/carddav/";
          passwordCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-mailbox"
          ];
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/contacts/mailbox";
        };
      };

      "gmail" = {
        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];

          clientIdCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-gmail-clientid"
          ];
          clientSecretCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-gmail-clientsecret"
          ];
          tokenFile = "/home/pinpox/.local/share/vdirsyncer-contacts-gmail-token";
        };
        remote = {
          type = "google_contacts";
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/contacts/gmail";
        };
      };
    };

    accounts.calendar.accounts = {

      "nextcloud" = {

        khal = {
          enable = true;
          type = "discover";
          priority = 1;
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];

          userNameCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-nextcloud-user"
          ];
        };
        remote = {
          type = "caldav";
          url = "https://files.pablo.tools/";

          passwordCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-nextcloud"
          ];
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/calendars/nextcloud";
        };
      };

      "mailbox" = {

        khal = {
          enable = true;
          type = "discover";
          priority = 1;
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];

          userNameCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-mailbox-user"
          ];
        };
        remote = {
          type = "caldav";
          url = "https://dav.mailbox.org/caldav/";

          passwordCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-mailbox"
          ];
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/calendars/mailbox";
        };
      };

      "icloud" = {

        khal = {
          enable = true;
          type = "discover";
          priority = 2;
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];
          userNameCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-icloud-user"
          ];
        };
        remote = {
          type = "caldav";
          url = "https://caldav.icloud.com/";
          passwordCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-icloud"
          ];
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/calendars/icloud";
        };
      };

      "gmail" = {

        khal = {
          enable = true;
          type = "discover";
          priority = 3;
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
            "displayname"
          ];
          clientIdCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-gmail-clientid"
          ];
          clientSecretCommand = [
            "${pkgs.passage}/bin/passage"
            "vdirsyncer-gmail-clientsecret"
          ];
          tokenFile = "/home/pinpox/.local/share/vdirsyncer-calendar-gmail-token";
        };
        remote = {
          type = "google_calendar";
        };
        local = {
          type = "filesystem";
          path = "/home/pinpox/.local/share/office/calendars/gmail";
        };
      };
    };
  };
}
