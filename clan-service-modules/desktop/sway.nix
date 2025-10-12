{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    # Some packages. Additional user-specific configuration and tweaking is
    # left to the user (either via extraModules or via home-manager).
    extraPackages = with pkgs; [
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      mako # notification system developed by swaywm maintainer
    ];
  };

  services.greetd = {

    # Only enable the greeter, if no display manager is enabled. This allows
    # using both the KDE and sway role at once.
    enable = !config.services.displayManager.sddm.enable;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'sway'";
        user = "greeter";
      };
    };
  };

}
