{ config, pkgs, lib, ... }: {
  # Picom X11 compositor
  services.picom = {
    backend = "glx";
    enable = true;
    # package = ;

    activeOpacity = "1.0";
    shadow = true;
  };
}
