{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.environment;
in
{

  options.pinpox.defaults.environment = {
    enable = mkEnableOption "Environment defaults";
  };

  config = mkIf cfg.enable {

    # System-wide environment variables to be set
    environment = {
      variables = {
        EDITOR = "nvim";
        GOPATH = "~/.go";
        VISUAL = "nvim";
        # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load
        # SVG files (important for icons)
        # GDK_PIXBUF_MODULE_FILE =
        #   "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
      };
    };
  };
}
