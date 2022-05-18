{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.pinpox.defaults.locale;
in
{
  options.pinpox.defaults.locale = {
    enable = mkEnableOption "Locale defaults";
  };

  config = mkIf cfg.enable {
    # Set localization and tty options
    i18n.defaultLocale = "en_DK.UTF-8";
    # i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "colemak";
    };

    # Set the timezone
    time.timeZone = "Europe/Berlin";
  };
}
