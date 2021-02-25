{ config, pkgs, ... }: {
  # Allow unfree licenced packages
  nixpkgs = { config.allowUnfree = true; };

  # Enable flakes
  nix = {

    # Save space by hardlinking store files
    autoOptimiseStore = true;

    # Enable flakes
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Clean up old generations after 30 days
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Users allowed to run nix
    allowedUsers = [ "root" ];
  };
}
