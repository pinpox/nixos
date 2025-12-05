{
  lib,
  config,
  clanLib,
  directory,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "wireguard";
  manifest.readme = "Wireguard star configuration";

  exports = lib.mapAttrs' (instanceName: _: {
    name = clanLib.buildScopeKey {
      inherit instanceName;
      serviceName = config.manifest.name;
    };
    value = {
      networking.priority = 1500;
    };
  }) config.instances;

  # Peer options and configuration
  roles.peer = {
    description = "Wireguard peer, connects to the server";
    interface = {
      options.extraIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "192.168.2.0/24" ];
        description = "Extra IPs to allow";
      };
    };

    perInstance =
      {
        instanceName,
        roles,
        machine,
        mkExports,
        ...
      }:
      {

        exports = mkExports {
          peer.hosts = [
            {
              plain = clanLib.getPublicValue {
                machine = machine.name;
                generator = "wireguard-${instanceName}-ip";
                file = "ipv4";
                flake = directory;
              };
            }
          ];
        };

        nixosModule =
          { config, ... }:
          {
            networking.wireguard.interfaces = {
              "${instanceName}" = {
                ips = [ "${config.clan.core.vars.generators."wireguard-${instanceName}-ip".files.ipv4.value}/24" ];
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
    description = "Wireguard controller, center of the star";
    interface = {
      options.endpoint = lib.mkOption {
        type = lib.types.str;
        example = "vpn.pablo.tools:51820";
        description = ''
          Endpoint where the contoller can be reached
        '';
      };
    };
    perInstance =
      {
        # settings,
        instanceName,
        roles,
        ...
      }:
      {
        nixosModule =
          { config, ... }:

          let
            ip = config.clan.core.vars.generators."wireguard-${instanceName}-ip".files.ipv4.value;
          in
          {

            # Enable ip forwarding, so wireguard peers can reach eachother
            boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

            networking.wireguard.interfaces."${instanceName}" = {

              ips = [ "${ip}/24" ];
              listenPort = 51820;

              peers = map (peer: {

                publicKey = (
                  builtins.readFile (
                    config.clan.core.settings.directory
                    + "/vars/per-machine/${peer}/wireguard-${instanceName}/publickey/value"
                  )
                );

                allowedIPs = [
                  (builtins.readFile (
                    config.clan.core.settings.directory
                    + "/vars/per-machine/${peer}/wireguard-${instanceName}-ip/ipv4/value"
                  ))
                ]
                ++ roles.peer.machines."${peer}".settings.extraIPs;

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

          clan.core.vars.generators =

            (lib.mapAttrs' (
              name: value:

              # Set IPs for each instance fo the host
              lib.nameValuePair "wireguard-${name}-ip" {
                prompts.ipv4.persist = true;
                files.ipv4.secret = false;

                # TODO, not implemented yet
                # files.ipv6.secret = false;
              }
            ) instances)
            //

              (lib.mapAttrs' (
                name: value:
                # Generate keys for each instance of the host
                lib.nameValuePair ("wireguard-" + name) {
                  files.publickey.secret = false;
                  files.privatekey = { };
                  runtimeInputs = with pkgs; [ wireguard-tools ];
                  script = ''
                    wg genkey > $out/privatekey
                    wg pubkey < $out/privatekey > $out/publickey
                  '';
                }
              ) instances);

          # Set the private key for each instance
          networking.wireguard.interfaces = builtins.mapAttrs (name: _: {
            privateKeyFile = "${config.clan.core.vars.generators."wireguard-${name}".files."privatekey".path}";
          }) instances;
        };
    };
}
