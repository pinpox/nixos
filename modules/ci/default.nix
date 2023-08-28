{ config, pkgs, lib, flake-self, nixpkgs, ... }:
with lib;
{
  options.pinpox.defaults = {
    CISkip = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Wheter this host should be skipped by the CI pipeline";
    };
  };
}
