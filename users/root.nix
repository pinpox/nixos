{ config, pkgs, lib, ... }: {

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {

    users.root = {
      isNormalUser = true;

      # Public ssh-keys that are authorized for the user. Fetched from homepage
      # and github profile.
      openssh.authorizedKeys.keyFiles = [
        (pkgs.fetchurl {
          url = "https://pablo.tools/ssh-key1";
          sha256 =
            "sha256:0h24djs4qahfgi5yfp14n8ljrsng36vhnn91klrz0qxqffxkrh7s";
        })
        (pkgs.fetchurl {
          url = "https://github.com/pinpox.keys1";
          sha256 =
            "sha256:1h24djs4qahfgi5yfp14n8ljrsng36vhnn91klrz0qxqffxkrh7s";
        })
      ];
    };
  };

  # Allow to run nix
  nix.allowedUsers = [ "root" ];
}
