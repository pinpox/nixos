{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.locale;
in
{

  options.pinpox.defaults.locale = {
    enable = mkEnableOption "Locale defaults";
    automatic-timezone = mkEnableOption "Automatic timezone based on location (for mobile machines)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Set localization and tty options
      i18n.defaultLocale = "en_DK.UTF-8";

      i18n.supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "en_DK.UTF-8/UTF-8"
      ];

      console = {
        keyMap = "colemak";
      };

      time.timeZone = mkDefault "Europe/Berlin";
    }

    (mkIf cfg.automatic-timezone {
      time.timeZone = null;
      services.automatic-timezoned.enable = true;
      services.geoclue2.geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    })
  ]);
}
