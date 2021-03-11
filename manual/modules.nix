{ lib, pkgs, config, ... }:
with lib; {

  imports = [
    # ./modules/base/desktop.nix
    ./modules/wireguard-client.nix
  ];
}
