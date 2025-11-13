{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let

  toggle-theme = pkgs.writeShellScriptBin "toggle-theme" (builtins.readFile ./toggle-theme.sh);

  cfg = config.pinpox.services.theme-switcher;

  # Build a script that calls all registered theme switch scripts
  themeWatcherScript = pkgs.writeShellScript "theme-watcher" ''
    update_theme() {
      local scheme=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)

      # Normalize the scheme value to prefer-light or prefer-dark
      local theme="prefer-dark"
      if [[ "$scheme" == "'prefer-light'" ]]; then
        theme="prefer-light"
      fi

      ${concatStringsSep "\n" (
        map (script: ''
          ${script} "$theme"
        '') cfg.scripts
      )}
    }

    # Set initial theme
    update_theme

    # Monitor dbus for changes to color-scheme
    ${pkgs.dconf}/bin/dconf watch /org/gnome/desktop/interface/color-scheme | while read -r line; do
      update_theme
    done
  '';
in
{
  options.pinpox.services.theme-switcher = {
    enable = mkEnableOption "theme switcher service";

    scripts = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of scripts to call when theme changes. Each script will be called
        with one argument: either "prefer-light" or "prefer-dark".
      '';
    };
  };

  config = mkIf cfg.enable {

    home.packages = [ toggle-theme ];

    systemd.user.services.theme-watcher = {
      Unit = {
        Description = "Theme watcher - updates applications on dbus theme change";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${themeWatcherScript}";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
