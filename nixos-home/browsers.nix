{ config, pkgs, lib, ... }:
let
  vars = import ./vars.nix;
  nur = import (builtins.fetchTarball
    "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
in {
  # Browserpass
  programs.browserpass = {
    enable = true;
    browsers = [ "chromium" "firefox" ];
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "gcbommkclmclpchllfjekcdonpmejbdp" # HTTPS Everywhere
      "lbhnkgjaoonakhladmcjkemebepeohkn" # Vim Tips New Tab
    ];
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    extensions = with nur.repos.rycee.firefox-addons; [
      bitwarden
      darkreader
      https-everywhere
      ublock-origin
    ];

    profiles = {
      pinpox = {

        # Extra preferences to add to user.js.
        # extraConfig = "";

        isDefault = true;
        settings = {
          "browser.startup.homepage" = "https://nixos.org";
          # "browser.display.background_color" = "#${vars.colors.base00}";
          # "browser.display.foreground_color" = "#${vars.colors.base05}";
          "browser.display.use_system_colors" = "true";
          "browser.anchor_color" = "#${vars.colors.base0A}";
          # "browser.display.use_document_colors" = "false";
          # "browser.search.region" = "GB";
          # "browser.search.isUS" = false;
          # "distribution.searchplugins.defaultLocale" = "en-GB";
          # "general.useragent.locale" = "en-GB";
          # "browser.bookmarks.showMobileBookmarks" = true;
          # TODO disable passwort manager
          # TODO if possible, enable sync (log in)
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "extensions.activeThemeID" = "default-theme@mozilla.org";
          "devtools.theme" = "dark";
        };

        userChrome = ''
                     :root {

             /* Minimal Functional Fox variables*/
            --mff-bg: #${vars.colors.base00};
            --mff-icon-color: #${vars.colors.base0D};
            --mff-nav-toolbar-padding: 8px;
            --mff-sidebar-bg: var(--mff-bg);
            --mff-sidebar-color: #${vars.colors.base04};

            --mff-tab-border-radius: 0px;
            --mff-tab-color: #${vars.colors.base05};
            --mff-tab-font-family: "${vars.font.normal.family}", sans;
            --mff-tab-font-size: 11pt;
            --mff-tab-font-weight: 400;
            --mff-tab-height: 32px;
            --mff-tab-pinned-bg: #${vars.colors.base0E};
            --mff-tab-selected-bg: #${vars.colors.base03};
            --mff-tab-selected-fg: #${vars.colors.base0A};
            --mff-tab-soundplaying-bg: #${vars.colors.base0E};

            --mff-urlbar-color: #${vars.colors.base05};
            --mff-urlbar-focused-color: #${vars.colors.base0D};
            --mff-urlbar-font-family: "${vars.font.normal.family}", serif;
            --mff-urlbar-font-size: 12pt;
            --mff-urlbar-font-weight: 700;
            --mff-urlbar-results-color: #${vars.colors.base05};
            --mff-urlbar-results-font-family: "${vars.font.normal.family}", serif;
            --mff-urlbar-results-font-size: 12pt;
            --mff-urlbar-results-font-weight: 700;
            --mff-urlbar-results-url-color: #${vars.colors.base0D};

            /*   --mff-tab-selected-bg: linear-gradient(90deg, rgba(232,74,95,1) 0%, rgba(255,132,124,1) 50%, rgba(254,206,168,1) 100%); */
            /*   --mff-urlbar-font-weight: 600; */

            /* Overriden Firefox variables*/
            --autocomplete-popup-background: var(--mff-bg) !important;
            --default-arrowpanel-background: var(--mff-bg) !important;
            --default-arrowpanel-color: #${vars.colors.base05}!important;
            --lwt-toolbarbutton-icon-fill: var(--mff-icon-color) !important;
            --panel-disabled-color: #${vars.colors.base05}00;
            --toolbar-bgcolor: var(--mff-bg) !important;
            --urlbar-separator-color: transparent !important;
          }

          /*
            _____ _   ___ ___
           |_   _/_\ | _ ) __|
             | |/ _ \| _ \__ \
             |_/_/ \_\___/___/

          */

          .tab-background[selected="true"] {
            background: var(--mff-tab-selected-bg) !important;
          }

          .tab-text[selected="true"] {
            color: #${vars.colors.base0A} !important;
          }

          .tab-background:not[visuallyselected] {
            background: var(--mff-tab-selected-bg) !important;
            colors: red;
            opacity: 0.5 !important;
          }

          /* This positions the tabs under the navaigator container */
          #titlebar {
            -moz-box-ordinal-group: 3 !important;
          }

          .tabbrowser-tab::after,
          .tabbrowser-tab::before {
            border-left: none !important;
          }

          .tab-background {
            border: none !important;
            background: #${vars.colors.base02} !important;
          }

          .tabbrowser-arrowscrollbox {
            margin-inline-start: 4px !important;
            margin-inline-end: 0px !important;
          }

          .tab-close-button {
           display: none !important;
          }

          .tab-text {
            font-family: var(--mff-tab-font-family);
            font-weight: var(--mff-tab-font-weight);
            font-size: var(--mff-tab-font-size) !important;
            color: var(--mff-tab-color);
          }

          /* Hide the favicon for tabs 

          hbox.tab-content .tab-icon-image {
            display: none !important;
          }

          */

          /* Show the favicon for tabs that are pinned */
          hbox.tab-content[pinned=true] .tab-icon-image {
            display: initial !important;
          }

          hbox.tab-content[pinned=true] .tab-text {
            display: none !important;
          }

          #tabbrowser-tabs {
            --tab-loading-fill: #033433 !important;

          }

          .tab-label-container:not([textoverflow]) {
            display: flex;
            overflow: hidden;
            justify-content: center;
          width: 50% !important;
            max-width: 50% !important;
            min-width: 50% !important;
          }

          /* .tab-label-container::after {
            content: "?" !important;

          } */

          .tab-line {
            display: none !important;
          }

          .tabbrowser-tab {
            border-radius: var(--mff-tab-border-radius) !important;
            border-width: 0;
            height: var(--mff-tab-height) !important;
            margin-bottom: 4px !important;
            margin-inline-end: 4px !important;
            margin-top: 4px !important;
            max-height: var(--mff-tab-height) !important;
            min-height: var(--mff-tab-height) !important;
          }

          .tabbrowser-tab[soundplaying="true"] {
            background-color: var(--mff-tab-soundplaying-bg) !important;
          }


          .tab-icon-sound {
            display: none !important;
          }

          /*
            _____ ___   ___  _    ___   _   ___
          |_   _/ _ \ / _ \| |  | _ ) /_\ | _ \
            | || (_) | (_) | |__| _ \/ _ \|   /
            |_| \___/ \___/|____|___/_/  \_\_|_\
          */

          .urlbar-icon > image {
            fill: var(--mff-icon-color) !important;
            color: var(--mff-icon-color) !important;
          }

          .toolbarbutton-text {
            color: var(--mff-icon-color)  !important;
          }
          .urlbar-icon {
            color: var(--mff-icon-color)  !important;

          }

          .toolbarbutton-icon {
          /* filter: drop-shadow(0 0 0.75rem crimson); */
          }

          #urlbar-results {
            font-family: var(--mff-urlbar-results-font-family);
            font-weight: var(--mff-urlbar-results-font-weight);
            font-size: var(--mff-urlbar-results-font-size) !important;
            color: var(--mff-urlbar-results-color) !important;
          }

          .urlbarView-row[type="bookmark"] > span{
            color: green !important;
          }

          .urlbarView-row[type="switchtab"] > span{
            color: orange !important;
          }

          .urlbarView-url, .search-panel-one-offs-container {
            color: var(--mff-urlbar-results-url-color) !important;
            font-family: var(--mff-urlbar-font-family);
            font-weight: var(--mff-urlbar-results-font-weight);
            font-size: var(--mff-urlbar-font-size) !important;
          }

          .urlbarView-favicon, .urlbarView-type-icon {
            display: none !important;
          }

          #urlbar-input {
            font-size: var(--mff-urlbar-font-size) !important;
            color: var(--mff-urlbar-color) !important;
            font-family: var(--mff-urlbar-font-family) !important;
            font-weight: var(--mff-urlbar-font-weight)!important;
            text-align: center !important;
          }

          #tracking-protection-icon-container, #identity-box {
            display: none;
          }

          #back-button > .toolbarbutton-icon{
            --backbutton-background: transparent !important;
            border: none !important;
          }


          toolbar {
            background-image: none !important;
          }

          #urlbar-background {
            opacity: .98 !important;
          }

          #navigator-toolbox, toolbaritem {
            border: none !important;
          }

          #urlbar-background {
            background-color: var(--mff-bg) !important;
            border: none !important;
          }

          .toolbar-items {
            background-color: var(--mff-bg) !important;
          }

          #sidebar-search-container {
            background-color: var(--mff-sidebar-bg) !important;
          }

          box.panel-arrowbox {
            display: none;
          }

          box.panel-arrowcontent {
            border-radius: 8px !important;
            border: none !important;
          }

          tab.tabbrowser-tab {
            overflow: hidden;
          }

          tab.tabbrowser-tab:hover {
            box-shadow: 0 1px 4px rgba(0,0,0,.05);
          }

          image#star-button {
            display: none;
          }

          toolbar#nav-bar {
            padding: var(--mff-nav-toolbar-padding) !important;
          }

          toolbar#nav-bar {
            padding: 4px !important;
          }

          #urlbar {
            max-width: 70% !important;
            margin: 0 15% !important;
            /* 	position: unset!important; */;
          }

          #urlbar-input:focus {
            color: var(--mff-urlbar-focused-color) !important;
          }


          .megabar[breakout-extend="true"]:not([open="true"]) > #urlbar-background {
            box-shadow: none !important;
            background-color: transparent !important;
          }

          toolbarbutton {
            box-shadow: none !important;
          }


          /*
            ___ ___ ___  ___ ___   _   ___
           / __|_ _|   \| __| _ ) /_\ | _ \
           \__ \| || |) | _|| _ \/ _ \|   /
           |___/___|___/|___|___/_/ \_\_|_\
          */

          .close-icon, .urlbar-icon {
            fill: var(--mff-icon-color) !important;
          }

          .sidebar-placesTree {
            color: var(--mff-sidebar-color) !important;
          }

          #sidebar-switcher-target {
          /*   color: white !important; */
          }

          #sidebar-box {
            --sidebar-background-color: var(--mff-sidebar-bg) !important;
          }

          splitter#sidebar-splitter {
            opacity: 0 !important;
          }

          splitter#sidebar-splitter {
            border: none !important;
            background-color: transparent !important;
          }

          image#sidebar-icon {
            display: none;
          }


          /*
              _   ___ ___  _____      _____  _   _  _ ___ _
             /_\ | _ \ _ \/ _ \ \    / / _ \/_\ | \| | __| |
            / _ \|   /   / (_) \ \/\/ /|  _/ _ \| .` | _|| |__
           /_/ \_\_|_\_|_\\___/ \_/\_/ |_|/_/ \_\_|\_|___|____|
           */

          .panel-arrowcontent {
            padding: 0px !important;
            margin: 0px !important;
          }

          toolbarseparator {
            display: none;
          }
                  '';
        userContent = ''
                    @import url("userChrome.css");

          /* Removes white loading page */
          @-moz-document url(about:blank), url(about:newtab), url(about:home) {
              html:not(#ublock0-epicker), html:not(#ublock0-epicker) body, #newtab-customize-overlay {
                background: var(--mff-bg) !important;
              }
            }


            /* Hide scrollbar */

            /*

            :root{
              scrollbar-width: none !important;
            }


            @-moz-document url(about:privatebrowsing) {

            :root{
              scrollbar-width: none !important;
            }

            */
            }

                  '';

      };
    };
  };
}
