{ config, pkgs, lib, ... }: {
  # System-wide environment variables to be set
  environment = {
    variables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      GOPATH = "~/.go";
      VISUAL = "${pkgs.neovim}/bin/nvim";
      # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load
      # SVG files (important for icons)
      GDK_PIXBUF_MODULE_FILE =
        "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
    };
  };
}
