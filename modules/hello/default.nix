{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.hello;
in {
  options.pinpox.services.hello = {
    enable = mkEnableOption "hello service";
    greeter = mkOption {
      type = types.str;
      default = "world";
      example = "universe";
      description = "A very friendly service that greets you";
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.hello ];

    systemd.services.hello = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart =
        "${pkgs.hello}/bin/hello -g'Hello, ${escapeShellArg cfg.greeter}!'";
    };
  };
}
