{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.xserver;
in {

  options.pinpox.services.xserver = {
    enable = mkEnableOption "X server";
  };

  config = mkIf cfg.enable {

    services.xserver = {
      enable = true;
      autorun = true;
      layout = "us";
      dpi = 125;
      xkbVariant = "colemak";
      xkbOptions = "caps:escape";

      libinput = {
        enable = true;
        touchpad.accelProfile = "flat";
      };

      config = ''
        Section "InputClass"
        Identifier "mouse accel"
        Driver "libinput"
        MatchIsPointer "on"
        Option "AccelProfile" "flat"
        Option "AccelSpeed" "0"
        EndSection
      '';

      displayManager.startx.enable = true;

      desktopManager = {
        xterm.enable = false;
        session = [{
          name = "home-manager";
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
           waitPID=$!
          '';
        }];
      };
    };
  };
}
