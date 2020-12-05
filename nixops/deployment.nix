{
  network.description = "My machines";

  porree =
  { config, pkgs, ... }:
  {
    deployment.targetHost = "nix.own";
    imports = [ ../machines/porree/configuration.nix ];
  };
}
