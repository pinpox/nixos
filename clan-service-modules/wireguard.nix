{ lib, ... }:
{
  _class = "clan.service";
  manifest.name = "wireguard";

  # Define what roles exist
  roles.peer = {
    interface = {
      # These options can be set via 'roles.client.settings'
      # options.ipRanges = with lib; mkOption { type = listOf str; };
      options.peerFileText =
        with lib;
        mkOption {
          type = types.str;
          default = "I'm a wg client!";
        };
    };

    # Maps over all instances and produces one result per instance.
    perInstance =
      {
        instanceName,
        settings,
        machine,
        roles,
        ...
      }:
      {
        # Analog to 'perSystem' of flake-parts.
        # For every instance of this service we will add a nixosModule to a client-machine
        nixosModule =
          { config, ... }:
          {
            environment.etc."wg-testfile-peer".text = settings.peerFileText;
          };
      };
  };

  roles.controller = {
    interface = {
      # These options can be set via 'roles.server.settings'
      # options.dynamicIp.enable =with lib; mkOption { type = bool; };

      options.controllerFileText =
        with lib;
        mkOption {
          type = types.str;
          default = "I'm a wg controller!";
        };

    };
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { ... }:
          {
            environment.etc."wg-testfile-controller".text = settings.controllerFileText;
          };
      };
  };

  # Maps over all machines and produces one result per machine.
  perMachine =
    { instances, machine, ... }:
    {
      # Analog to 'perSystem' of flake-parts.
      # For every machine of this service we will add exactly one nixosModule to a machine
      nixosModule =
        { config, ... }:
        {
          environment.etc."wg-testfile-all".text = "I'm part of the wg service module";
        };
    };
}
