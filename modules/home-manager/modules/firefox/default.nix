{ config, pkgs, lib, nur, utils, ... }:
with lib;
let
  vars = import ../vars.nix;
  cfg = config.pinpox.programs.firefox;
in
{
  options.pinpox.programs.firefox.enable = mkEnableOption "firefox browser";

  config = mkIf cfg.enable {

    # Browserpass
    programs.browserpass = {
      enable = true;
      # browsers = [ "chromium" "firefox" ];
      browsers = [ "firefox" ];
    };

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
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

            # Set the homepage
            "browser.startup.homepage" = "https://nixos.org";

            # Export bookmarks to bookmarks.html when closing firefox
            "browser.bookmarks.autoExportHTML" = "true";

            # Path where to export. Default is:
            # ~/.mozilla/firefox/pinpox/bookmarks.html
            # "browser.bookmarks.file" = 

            # "browser.display.background_color" = "#${vars.colors.Black}";
            # "browser.display.foreground_color" = "#${vars.colors.White}";
            "browser.display.use_system_colors" = "true";
            "browser.anchor_color" = "#${vars.colors.Yellow}";
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

          userChrome = builtins.readFile
            (utils.renderMustache "userChrome.css" ./userchrome.css.mustache
              vars);

          # TODO
          userContent = ''
            @import url("userChrome.css");

            /* Removes white loading page */
            @-moz-document url(about:blank), url(about:newtab), url(about:home) {
              html:not(#ublock0-epicker), html:not(#ublock0-epicker) body, #newtab-customize-overlay {
                background: var(--mff-bg) !important;
              }
            }
          '';
        };
      };
    };
  };
}
