{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.pinpox.services.hello;
in {
  options.pinpox.services.hello = {
    enable = mkEnableOption "hello service";
    greeter123 = mkOption {
      type = types.str;
      default = "world";
      description = "test";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hello = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.hello}/bin/hello -g'Hello, ${escapeShellArg cfg.greeter}!'";
    };
  };
}
