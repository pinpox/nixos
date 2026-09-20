{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.noctalia;
  c = config.pinpox.colors;
  json = pkgs.formats.json { };

  # Official plugin repository (noctalia-shell 4.x line). Pinned; bump rev+hash
  # to update privacy-indicator.
  noctalia-plugins = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "legacy-v4-plugins";
    rev = "718db35d3b7134d87458451a844ad8b15eba7d3d";
    hash = "sha256-hh9LK8k/UURDwaopi42CACfPM/3p+dyCDcRi3U1SFuw=";
  };

  # noctalia keeps per-plugin user settings at plugins/<id>/settings.json, so
  # an upstream plugin with custom settings is the upstream tree plus that file.
  privacy-indicator = pkgs.runCommand "noctalia-plugin-privacy-indicator" { } ''
    cp -r ${noctalia-plugins}/privacy-indicator $out
    chmod u+w $out
    cp ${
      json.generate "settings.json" {
        hideInactive = true;
        micFilterRegex = "rnnoise";
      }
    } $out/settings.json
  '';

  # Plugin id -> directory. Ids must match manifest.json "id"; the bar widgets
  # in settings.json reference them as "plugin:<id>".
  plugins = {
    firefox-history = ./plugins/firefox-history;
    himalaya-mail = ./plugins/himalaya-mail;
    noctalia-askpass = ./plugins/noctalia-askpass;
    inherit privacy-indicator;
  };

  # Registry state noctalia would otherwise build up via its plugin manager.
  # Every deployed plugin is enabled; sourceUrl only matters for re-downloads,
  # which never happen since the directories always exist. The source itself is
  # disabled: an enabled source is git-cloned on every start for an update
  # check, and updates are done by bumping the pin above, not from the UI.
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
  pluginsRegistry = {
    version = 2;
    sources = [
      {
        enabled = false;
        name = "Noctalia Plugins";
        url = pluginSource;
      }
    ];
    states = mapAttrs (_: _: {
      enabled = true;
      sourceUrl = pluginSource;
    }) plugins;
  };

  terminalColors = {
    normal = {
      black = "#${c.Black}";
      red = "#${c.Red}";
      green = "#${c.Green}";
      yellow = "#${c.Yellow}";
      blue = "#${c.Blue}";
      magenta = "#${c.Magenta}";
      cyan = "#${c.Cyan}";
      white = "#${c.White}";
    };
    bright = {
      black = "#${c.BrightBlack}";
      red = "#${c.BrightRed}";
      green = "#${c.BrightGreen}";
      yellow = "#${c.BrightYellow}";
      blue = "#${c.BrightBlue}";
      magenta = "#${c.BrightMagenta}";
      cyan = "#${c.BrightCyan}";
      white = "#${c.BrightWhite}";
    };
  };

  # Predefined scheme "pinpox", selected by colorSchemes.predefinedScheme in
  # settings.json. Both variants derive from the shared pinpox.colors palette.
  colorscheme = {
    dark = {
      mPrimary = "#${c.Blue}";
      mOnPrimary = "#${c.Black}";
      mSecondary = "#${c.Black}";
      mOnSecondary = "#${c.White}";
      mTertiary = "#${c.Green}";
      mOnTertiary = "#${c.Black}";
      mError = "#${c.Red}";
      mOnError = "#${c.White}";
      mSurface = "#${c.Black}";
      mOnSurface = "#${c.White}";
      mHover = "#${c.BrightBlack}";
      mOnHover = "#${c.White}";
      mSurfaceVariant = "#${c.Black}";
      mOnSurfaceVariant = "#${c.BrightBlue}";
      mOutline = "#${c.BrightBlack}";
      mShadow = "#${c.Black}";
      terminal = terminalColors // {
        background = "#${c.Black}";
        foreground = "#${c.White}";
        cursor = "#${c.White}";
        cursorText = "#${c.Black}";
        selectionBackground = "#${c.Blue}";
        selectionForeground = "#${c.Black}";
      };
    };
    light = {
      mPrimary = "#${c.Blue}";
      mOnPrimary = "#${c.BrightWhite}";
      mSecondary = "#${c.Cyan}";
      mOnSecondary = "#${c.BrightWhite}";
      mTertiary = "#${c.Green}";
      mOnTertiary = "#${c.BrightWhite}";
      mError = "#${c.Red}";
      mOnError = "#${c.BrightWhite}";
      mSurface = "#${c.BrightWhite}";
      mOnSurface = "#${c.Black}";
      mHover = "#${c.White}";
      mOnHover = "#${c.Black}";
      mSurfaceVariant = "#${c.White}";
      mOnSurfaceVariant = "#${c.Blue}";
      mOutline = "#${c.White}";
      mShadow = "#${c.White}";
      terminal = terminalColors // {
        background = "#${c.BrightWhite}";
        foreground = "#${c.Black}";
        cursor = "#${c.Black}";
        cursorText = "#${c.BrightWhite}";
        selectionBackground = "#${c.Blue}";
        selectionForeground = "#${c.BrightWhite}";
      };
    };
  };
in
{
  options.pinpox.programs.noctalia.enable = mkEnableOption "noctalia-shell bar configuration";

  # Config for noctalia-shell (the quickshell-based 4.x line; home-manager's
  # programs.noctalia targets the v5 rewrite and its config.toml). The shell is
  # launched by the sway module. settings.json is a store symlink, so noctalia
  # cannot persist changes made in its settings UI; edit settings.json here and
  # rebuild instead (noctalia reloads on the symlink swap). colors.json is left
  # to noctalia, which regenerates it from the selected scheme.
  config = mkIf cfg.enable {
    xdg.enable = true;
    xdg.configFile = {
      "noctalia/settings.json".source = ./settings.json;
      "noctalia/plugins.json".source = json.generate "plugins.json" pluginsRegistry;
      "noctalia/colorschemes/pinpox/pinpox.json".source = json.generate "pinpox.json" colorscheme;
    }
    // mapAttrs' (id: dir: nameValuePair "noctalia/plugins/${id}" { source = dir; }) plugins;
  };
}
