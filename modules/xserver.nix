{ config, pkgs, lib, ... }: {
  # Enable the X11 windowing system.
  services.xserver = {
    # videoDrivers = [ "nvidia" ];
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

    displayManager = { startx.enable = true; };
  };
}
