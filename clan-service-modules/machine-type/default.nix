{ lib, ... }:
{
  _class = "clan.service";
  manifest.name = "machine-type";

  roles.server = {
    interface = {
      # options.port = lib.mkOption {
      #   type = lib.types.int;
      #   example = 0;
      #   description = ''
      #     bla
      #   '';
      # };
    };

    perInstance =
      { settings, ... }:
      {
        nixosModule = {
          imports = [ ./server.nix ];
          _module.args = { inherit settings; };
        };
      };
  };

  roles.desktop.perInstance =
    { settings, ... }:
    {
      nixosModule = {
        imports = [ ./desktop.nix ];
        _module.args = { inherit settings; };
      };
    };

  perMachine =
    { instances, ... }:
    {
      nixosModule =
        { config, pkgs, ... }:
        {
          hardware.enableRedistributableFirmware = true;
          metrics.node.enable = true;
        };
    };
}
