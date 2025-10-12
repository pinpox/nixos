{
  lib,
  pkgs,
  # config,
  ...
}:
with lib;
{

  # imports = [ ];
  # environment.systemPackages = with pkgs; [ ripgrep ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'sway'";
        user = "greeter";
      };

      # river_session = {
      #   command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-river";
      #   user = "greeter";
      # };
    };
  };

}
