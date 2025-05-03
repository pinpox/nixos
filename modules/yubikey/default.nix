{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.yubikey;
in
{

  options.pinpox.defaults.yubikey.enable = mkEnableOption "yubikey defaults";

  config = mkIf cfg.enable {

    # We run the agent via home-manger
    programs.ssh.startAgent = false;
    services.yubikey-agent.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
