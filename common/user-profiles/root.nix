{ config, pkgs, lib, ...}: {

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {

    users.root= {
      isNormalUser = true;

      # Public ssh-keys that are authorized for the user. Fetched from homepage
      # and github profile.
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl { url = "https://pablo.tools/ssh-key"; })
        (builtins.fetchurl { url = "https://github.com/pinpox.keys"; })
      ];
    };
  };

  # Allow to run nix
  nix.allowedUsers = [ "root" ];
}
