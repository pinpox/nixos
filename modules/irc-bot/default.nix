{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.irc-bot;
in {

  options.pinpox.services.irc-bot = {
    enable = mkEnableOption "the irc bot.";
  };

  config = mkIf cfg.enable {
    # Here goes the config
  };
}
