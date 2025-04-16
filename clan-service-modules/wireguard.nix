# TODO add assertions like this:
# perMachine = { instances }:
#     # ...
#            instanceNames = builtins.attrNames instances;
#    # .....
#            assertions =
#             [
#               {
#                 assertion = builtins.length instanceNames == 1;
#                 message = "The zerotier module currently only supports one instance per machine, but found ${builtins.toString instanceNames} on machine ${config.clan.core.settings.machine.name}";
#               }
#             ]
#             # TODO: remove this assertion once we start verifying constraints again
#             ++ (lib.mapAttrsToList (_instanceName: instance: {
#               assertion = builtins.length (lib.attrNames instance.roles.controller.machines) == 1;
#               message = "ZeroTier only supports one controller per network";
#             }) instances);

{ lib, ... }:
{
  _class = "clan.service";
  manifest.name = "wireguard";

  # Define what roles exist
  roles.peer = {
    interface = {

      # These options can be set via 'roles.client.settings'
      options.ip = lib.mkOption {
        type = lib.types.str;
        # default = "0.0.0.0";
        example = "192.168.8.1";
        description = ''
          IP address of the host.
        '';
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

            networking.wireguard.interfaces =
              let
                # Get all controller names:
                allControllerNames = (lib.attrNames roles.controller.machines);
              in
              {

                "${instanceName}" = {

                  ips = [ "${settings.ip}/24" ];

                  peers = map (name: {

                    # Public key of the server (not a file path).
                    publicKey = (
                      builtins.readFile (
                        config.clan.core.settings.directory
                        + "/vars/per-machine/${name}/wireguard-${instanceName}/publickey/value"
                      )
                    );

                    # Don't forward all the traffic via VPN, only particular subnets
                    allowedIPs = [ "192.168.8.0/24" ];

                    # Server IP and port.
                    endpoint = roles.controller.machines."${name}".settings.endpoint;

                    # Send keepalives every 25 seconds. Important to keep NAT tables
                    # alive.
                    persistentKeepalive = 25;

                  }) allControllerNames;
                };
              };
          };
      };
  };

  roles.controller = {
    interface = {
      # These options can be set via 'roles.server.settings'
      # options.dynamicIp.enable =with lib; mkOption { type = bool; };

      options.endpoint = lib.mkOption {
        type = lib.types.str;
        example = "vpn.pablo.tools:51820";
        description = ''
          Endpoint where the contoller can be reached
        '';
      };

      options.ip = lib.mkOption {
        type = lib.types.str;
        example = "192.168.8.1";
        description = ''
          IP address of the host.
        '';
      };
    };
    perInstance =
      {
        settings,
        instanceName,
        roles,
        ...
      }:
      {
        nixosModule =
          { config, ... }:
          {

            # Enable ip forwarding, so wireguard peers can reach eachother
            boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

            networking.wireguard.interfaces."${instanceName}" = {

              ips = [ "${settings.ip}/24" ];
              listenPort = 51820;

              peers = map (peer: {

                publicKey = (
                  builtins.readFile (
                    config.clan.core.settings.directory
                    + "/vars/per-machine/${peer}/wireguard-${instanceName}/publickey/value"
                  )
                );

                allowedIPs = [
                  # TODO we might want to add extra ip's here, e.g. for birne?
                  roles.peer.machines."${peer}".settings.ip
                ];

                persistentKeepalive = 25;
              }) (lib.attrNames roles.peer.machines);

            };
          };
      };
  };

  # Maps over all machines and produces one result per machine.
  perMachine =
    {
      instances,
      machine,
      # instanceName,
      ...
    }:
    {
      # Analog to 'perSystem' of flake-parts.
      # For every machine of this service we will add exactly one nixosModule to a machine
      nixosModule =
        { config, pkgs, ... }:
        {

          networking.wireguard.interfaces = builtins.mapAttrs (name: _: {
            privateKeyFile = "${config.clan.core.vars.generators."wireguard-${name}".files."privatekey".path}";
          }) instances;

          clan.core.vars.generators =

            # mapAttrs' (name: value: nameValuePair ("foo_" + name) ("bar-" + value))
            #    { x = "a"; y = "b"; }
            # => { foo_x = "bar-a"; foo_y = "bar-b"; }

            lib.mapAttrs' (
              name: value:
              lib.nameValuePair ("wireguard-" + name) {
                files.publickey.secret = false;
                files.privatekey = { };
                runtimeInputs = with pkgs; [ wireguard-tools ];
                script = ''
                  wg genkey > $out/privatekey
                  wg pubkey < $out/privatekey > $out/publickey
                '';
              }
            ) instances;
        };
    };
}
