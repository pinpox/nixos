{ config, pkgs, lib, ... }: {

  # Set localization and tty options
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "colemak";
  };

  # Set the timezone
  time.timeZone = "Europe/Berlin";
}
