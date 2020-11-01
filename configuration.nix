{ config, pkgs, options, ... }:
let
  let hostname = "kartoffel";
in {
  networking.hostName = hostname;
  imports = [ (machines/${hostname}/configuration.nix ];
}
