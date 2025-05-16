{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
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

      profiles = {
        pinpox = {

          # containers = {

          #   # dangerous = {
          #   #   color = "red";
          #   #   icon = "fruit";
          #   #   id = 2;
          #   # };

          #   work = {
          #     color = "blue";
          #     icon = "cart";
          #     id = 1;
          #   };
          # };

          search = {
            force = true;
            engines = {
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
            };
          };

          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            bitwarden
            darkreader
            web-search-navigator
            ublock-origin
            simple-tab-groups
          ];

          isDefault = true;
          settings = {

            # 0 => blank page
            # 1 => your home page(s) {default}
            # 2 => the last page viewed in Firefox
            # 3 => previous session windows and tabs
            "browser.startup.page" = "3";

            # Set the homepage
            "browser.startup.homepage" = "https://nixos.org";

            # Export bookmarks to bookmarks.html when closing firefox
            "browser.bookmarks.autoExportHTML" = "true";

            # Path where to export. Default is:
            # ~/.mozilla/firefox/pinpox/bookmarks.html
            # "browser.bookmarks.file" =

            # "browser.display.background_color" = "#${config.pinpox.colors.Black}";
            # "browser.display.foreground_color" = "#${config.pinpox.colors.White}";
            "browser.display.use_system_colors" = "true";
            "browser.anchor_color" = "#${config.pinpox.colors.Yellow}";
            "browser.display.use_document_colors" = "false";
            # "browser.search.region" = "GB";
            # "browser.search.isUS" = false;
            # "distribution.searchplugins.defaultLocale" = "en-GB";
            # "general.useragent.locale" = "en-GB";
            # "browser.bookmarks.showMobileBookmarks" = true;
            # TODO if possible, enable sync (log in)
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "extensions.activeThemeID" = "default-theme@mozilla.org";
            "devtools.theme" = "dark";
            "dom.security.https_only_mode" = "true"; # HTTPS everywhere

            # Disable password managger
            "signon.rememberSignons" = "false";
            "signon.autofillForms" = "false";
            "signon.autofillForms.http" = "false";
          };

          # userChrome = builtins.readFile
          #   (utils.renderMustache "userChrome.css" ./userchrome.css.mustache
          #     { colors = config.pinpox.colors; font = fonts; });

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
