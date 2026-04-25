{
  pkgs,
  config,
  lib,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.claude-code;
  mics-skills = flake-self.inputs.mics-skills;
  mics-packages = mics-skills.packages.${pkgs.stdenv.hostPlatform.system};

  firefoxPrefs = {
    "xpinstall.signatures.required" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.enabledScopes" = 15;
    "browser.shell.checkDefaultBrowser" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.reportingpolicy.firstRun" = false;
    "browser.uiCustomization.state" = builtins.toJSON {
      placements = {
        widget-overflow-fixed-list = [ ];
        unified-extensions-area = [ ];
        nav-bar = [
          "back-button"
          "forward-button"
          "stop-reload-button"
          "urlbar-container"
          "downloads-button"
          "browser-cli-controller_thalheim_io-browser-action"
          "unified-extensions-button"
        ];
        toolbar-menubar = [ "menubar-items" ];
        TabsToolbar = [ "tabbrowser-tabs" "new-tab-button" "alltabs-button" ];
        PersonalToolbar = [ "personal-bookmarks" ];
      };
      seen = [ "browser-cli-controller_thalheim_io-browser-action" ];
      dirtyAreaCache = [ "nav-bar" ];
      currentVersion = 20;
      newElementCount = 0;
    };
  };

  userJs = pkgs.writeText "browser-cli-user.js" (concatStringsSep "\n" (
    mapAttrsToList (k: v: "user_pref(${builtins.toJSON k}, ${builtins.toJSON v});") firefoxPrefs
  ));

  browser-cli-firefox = pkgs.writeShellScriptBin "browser-cli-firefox" ''
    set -euo pipefail

    PROFILE="$(mktemp -d)"
    trap 'rm -rf "$PROFILE"' EXIT

    cp ${userJs} "$PROFILE/user.js"

    mkdir -p "$PROFILE/extensions"
    cp ${mics-packages.browser-cli-extension}/browser-cli-extension.xpi \
      "$PROFILE/extensions/browser-cli-controller@thalheim.io.xpi"

    exec ${pkgs.firefox-devedition}/bin/firefox-devedition \
      --no-remote -profile "$PROFILE" "$@"
  '';
in
{
  imports = [
    mics-skills.homeModules.default
  ];

  options.pinpox.programs.claude-code = {
    enable = mkEnableOption "claude-code";
  };

  config = mkIf cfg.enable {

    home.packages = [
      pkgs.claude-code
      browser-cli-firefox
    ];

    programs.mics-skills = {
      enable = true;
      package = mics-packages;
      skills = [ "browser-cli" ];
    };

    # Declarative settings via settings.local.json (merged with mutable settings.json)
    home.file.".claude/settings.local.json".text = builtins.toJSON {
      permissions.allow = [
        "Bash(browser-cli:*)"
        "Bash(browser-cli-firefox:*)"
        "Bash(browser-cli-server:*)"
        "Read(/tmp/**)"
      ];
    };

    # Supplement the browser-cli skill with browser launch instructions
    home.file.".claude/skills/browser-cli-setup/SKILL.md".text = ''
      ---
      name: browser-cli-setup
      description: How to start Firefox with the browser-cli extension pre-installed. Use this before using browser-cli commands.
      ---

      # Starting the browser

      Before using `browser-cli`, you must launch Firefox Developer Edition
      with the browser-cli extension already installed. Run:

      ```bash
      browser-cli-firefox &
      ```

      This starts Firefox Developer Edition with a temporary profile that has:
      - The browser-cli WebExtension pre-installed
      - Extension signature checks disabled
      - Telemetry disabled

      After the browser is running, use `browser-cli` commands as documented
      in the browser-cli skill.
    '';
  };
}
