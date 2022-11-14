{ config, pkgs, lib, pinpox-keys, ... }: {

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
      openssh.authorizedKeys.keyFiles = [ pinpox-keys ];
    };
  };

  # Allow to run nix
  nix.settings.allowed-users = [ "pinpox" ];
}
