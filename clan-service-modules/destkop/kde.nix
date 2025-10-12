{
  lib,
  pkgs,
  # config,
  ...
}:
with lib;
{


  # imports = [ ];
  # services.xserver.enable = true; # optional

  services = {
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    desktopManager.plasma6.enable = true;
  };

}
