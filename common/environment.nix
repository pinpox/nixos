{ config, pkgs, lib, ... }: {
  # System-wide environment variables to be set
  environment = {
    variables = {
      EDITOR = "nvim";
      GOPATH = "~/.go";
      VISUAL = "nvim";
      # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load
      # SVG files (important for icons)
      GDK_PIXBUF_MODULE_FILE =
        "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
    };

    # Needed for yubikey to work
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
  };
}
