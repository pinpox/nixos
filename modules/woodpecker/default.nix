{ config, lib, pkgs, ... }:

{
  imports = [
    ./woodpecker-server.nix
    ./woodpecker-agent.nix
  ];
}
