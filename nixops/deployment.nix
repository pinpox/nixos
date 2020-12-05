{
  network.description = "My machines";

  porree =
  { config, pkgs, ... }:
  {
    # TODO replace this with a hostname that is in /etc/hosts
    deployment.targetHost = "94.16.114.42";
    imports = [ ../machines/porree/configuration.nix ];
  };

  kartoffel =
  { config, pkgs, ... }:
  {
    # TODO replace this with a hostname that is in /etc/hosts
    deployment.targetHost = "192.168.7.2";
    imports = [ ../machines/kartoffel/configuration.nix ];
  };

  # ahorn =
  # { config, pkgs, ... }:
  # {
  #   deployment.targetHost = "ahorn";
  #   imports = [ ../machines/ahorn/configuration.nix ];
  # };
}
