{ lib, ... }:
{
  _class = "clan.service";
  manifest.name = "wireguard";

  # Peer options and configuration
  roles.peer = {

    interface = {

      options.ip = lib.mkOption {
        type = lib.types.str;
        example = "192.168.8.1";
        description = ''
          IP address of the host.
        '';
      };

      options.extraIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = [ "192.168.2.0/24" ];
        description = ''
          IP address of the host.
        '';
      };
    };

    perInstance =
      {
        instanceName,
        settings,
        roles,
        ...
      }:
      {
        # Analog to 'perSystem' of flake-parts.
        # For every instance of this service we will add a nixosModule to a client-machine
        nixosModule =
          { config, ... }:
          {
            networking.wireguard.interfaces = {
              "${instanceName}" = {
                ips = [ "${settings.ip}/24" ];
                peers = map (name: {
                  # Public key of the server
                  publicKey = (
                    builtins.readFile (
                      config.clan.core.settings.directory
                      + "/vars/per-machine/${name}/wireguard-${instanceName}/publickey/value"
                    )
                  );

                  # Don't forward all the traffic via VPN, only particular subnets
                  allowedIPs = [ "192.168.8.0/24" ];

                  # Server IP and port
                  endpoint = roles.controller.machines."${name}".settings.endpoint;

                  # Send keepalives every 25 seconds to keep NAT tables alive
                  persistentKeepalive = 25;

                }) (lib.attrNames roles.controller.machines);
              };
            };
          };
      };
  };

  # Controller options and configuration
  roles.controller = {
    interface = {
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
                ] ++ roles.peer.machines."${peer}".settings.extraIPs;

                persistentKeepalive = 25;
              }) (lib.attrNames roles.peer.machines);

            };
          };
      };
  };

  # Maps over all machines and produces one result per machine, regardless of role
  perMachine =
    { instances, ... }:
    {
      nixosModule =
        { config, pkgs, ... }:
        {

          # Generate keys for each instance of the host
          clan.core.vars.generators = lib.mapAttrs' (
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

          # Set the private key for each instance
          networking.wireguard.interfaces = builtins.mapAttrs (name: _: {
            privateKeyFile = "${config.clan.core.vars.generators."wireguard-${name}".files."privatekey".path}";
          }) instances;
        };
    };
}
