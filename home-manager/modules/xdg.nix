{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
  xdg = {
    enable = true;
    configFile = { };
  };
}
