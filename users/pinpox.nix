{ config, pkgs, lib, ... }: {

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {

    # For Virtualbox
    extraGroups = { vboxusers.members = [ "pinpox" ]; };

    # Shell is set to zsh for all users as default.
    defaultUserShell = pkgs.zsh;

    users.pinpox = {
      isNormalUser = true;
      home = "/home/pinpox";
      description = "Pablo Ovelleiro Corral";
      extraGroups =
        [ "docker" "wheel" "networkmanager" "audio" "libvirtd" "dialout" ];
      shell = pkgs.zsh;

      # Public ssh-keys that are authorized for the user. Fetched from github
      openssh.authorizedKeys.keyFiles = [
        (pkgs.fetchurl {
          url = "https://github.com/pinpox.keys";
          # sha256 = "0si2xncbqjrxn42hvwj98in83mk2cl4rlanf32rlc8lxa2d79q5v";
          sha256 =
            "sha256:0h24djs4qahfgi5yfp14n8ljrsng36vhnn91klrz0qxqffxkrh7s";
        })
      ];
    };
  };

  # Allow to run nix
  nix.allowedUsers = [ "pinpox" ];
}
