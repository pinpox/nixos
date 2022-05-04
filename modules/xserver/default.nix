{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.xserver;
  # i3kde =

  #   pkgs.writeTextFile {
  #     name = "plasma-i3-xsession";
  #     destination = "/share/xsessions/plasma-i3.desktop";
  #     text = ''
  #       [Desktop Entry]
  #       Type=XSession
  #       Exec=${pkgs.coreutils}/bin/env KDEWM=${pkgs.i3}/bin/i3 /not/sure/what/this/is/bin/startplasma-x11
  #       DesktopNames=KDE
  #       Name=Plasma with i3
  #       Comment=Plasma with i3
  #     '';

  #   } //{
  #     passthru = { providedSessions = [ "sm.puri.Phosh" ]; };
  #   } ;
in {

  options.pinpox.services.xserver = { enable = mkEnableOption "X server"; };

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

      # displayManager.startx.enable = true;

      # displayManager.sddm.enable = true;

      displayManager = {
        sddm.enable = true;
        defaultSession = "myplasmai3session";
        session = [{
          manage = "desktop";
          name = "myplasmai3session";
          start =
            "exec env KDEWM=${pkgs.i3-gaps}/bin/i3 ${pkgs.plasma-workspace}/bin/startplasma-x11";
        }];
      };

      # displayManager.extraSessionFilesPackages = [i3kde];
      desktopManager.plasma5.enable = true;
      windowManager.i3.enable = true;

      # desktopManager = {
      #   xterm.enable = false;
      #   session = [{
      #     name = "home-manager";
      #     start = ''
      #        ${pkgs.runtimeShell} $HOME/.hm-xsession &
      #       waitPID=$!
      #     '';
      #   }];
      # };
    };
  };
}
