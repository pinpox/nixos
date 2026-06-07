{ lib, ... }:
let
  # Both roles accept arbitrary extra CLI args; pure passthrough flags live
  # there rather than getting their own option each.
  mkExtraArgs =
    binary:
    lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments appended to `${binary}`.";
    };
in
{
  _class = "clan.service";
  manifest.name = "n2n";
  manifest.description = "n2n peer-to-peer VPN (https://github.com/ntop/n2n).";
  manifest.readme = ''
    Two roles:
      - supernode: introduction registry and packet relay. Listens on a UDP
        port that must be reachable by every edge in the instance.
      - edge: VPN member. Creates a TAP interface and joins the community
        formed by all edges sharing the same instance.

    Multiple instances of this service can coexist on the same clan and even
    on the same machine: every systemd unit, TAP device, and `vars` generator
    is qualified by the instance name. When colocating instances on one host,
    override `port` (supernode) and pass any per-host edge tweaks via
    `extraArgs` to avoid collisions.

    The community encryption key (`-k`) is generated once per instance as a
    shared `vars` secret and distributed only to the edge machines; the
    supernode never sees it (n2n by design cannot decrypt community traffic).
  '';
  manifest.categories = [ "Network" ];

  roles.supernode = {
    description = "n2n supernode: introduction registry and packet relay.";
    interface =
      { lib, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = ''
              Public hostname or IP address that edges use to reach this
              supernode. No default — each supernode machine must set its
              own routable address.
            '';
            example = "supernode.example.com";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 7654;
            description = "UDP port the supernode listens on.";
          };
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open `port` in the host firewall.";
          };
          extraArgs = mkExtraArgs "supernode";
        };
      };

    perInstance =
      {
        instanceName,
        settings,
        ...
      }:
      {
        nixosModule =
          { pkgs, lib, ... }:
          {
            networking.firewall.allowedUDPPorts = lib.optional settings.openFirewall settings.port;

            systemd.services."n2n-supernode-${instanceName}" = {
              description = "n2n supernode (instance: ${instanceName})";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.n2n}/bin/supernode -f -p ${toString settings.port} ${lib.escapeShellArgs settings.extraArgs}";
                Restart = "always";
                RestartSec = 5;

                # Supernode does not touch any TAP device, so a dynamic,
                # unprivileged user is enough.
                DynamicUser = true;
                AmbientCapabilities = lib.optional (settings.port < 1024) "CAP_NET_BIND_SERVICE";
                CapabilityBoundingSet = lib.optional (settings.port < 1024) "CAP_NET_BIND_SERVICE";
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
                PrivateDevices = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [
                  "AF_INET"
                  "AF_INET6"
                  "AF_UNIX"
                ];
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                SystemCallArchitectures = "native";
                SystemCallFilter = [
                  "@system-service"
                  "~@privileged"
                ];
              };
            };
          };
      };
  };

  roles.edge = {
    description = "n2n edge: joins the community via the configured supernodes.";
    interface =
      { lib, ... }:
      {
        options = {
          community = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            defaultText = lib.literalExpression "instanceName";
            description = ''
              Community name (`-c`). Defaults to the clan service instance
              name, which gives each instance its own isolated VPN.
              Truncated to the first 16 bytes by n2n.
            '';
          };
          extraArgs = mkExtraArgs "edge";
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
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            generator = "n2n-${instanceName}";

            community = if settings.community != null then settings.community else instanceName;
            supernodes = lib.mapAttrsToList (_name: m: "${m.settings.host}:${toString m.settings.port}") (
              roles.supernode.machines or { }
            );

            args =
              lib.concatMap (sn: [
                "-l"
                sn
              ]) supernodes
              ++ settings.extraArgs;

            # Wrapper that loads the community key from systemd's credentials
            # store into N2N_KEY (read by edge as a fallback for -k). Keeps the
            # secret off the command line and out of /proc/<pid>/cmdline.
            runner = pkgs.writeShellScript "n2n-edge-${instanceName}-run" ''
              set -eu
              N2N_KEY="$(cat "$CREDENTIALS_DIRECTORY/key")"
              export N2N_KEY
              exec ${pkgs.n2n}/bin/edge -f \
                -d n2n-${instanceName} \
                -c ${community} \
                ${lib.escapeShellArgs args}
            '';

            keyPath = config.clan.core.vars.generators.${generator}.files.key.path;
          in
          {
            clan.core.vars.generators.${generator} = {
              share = true;
              files.key = { }; # secret by default
              runtimeInputs = with pkgs; [
                openssl
                coreutils
              ];
              script = ''
                openssl rand -base64 48 | tr -d '\n' > $out/key
              '';
            };

            systemd.services."n2n-edge-${instanceName}" = {
              description = "n2n edge (instance: ${instanceName})";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = runner;
                LoadCredential = [ "key:${keyPath}" ];
                Restart = "always";
                RestartSec = 5;

                # Drop to a dedicated dynamic user with just enough capability
                # to create and configure the TAP interface.
                DynamicUser = true;
                AmbientCapabilities = [
                  "CAP_NET_ADMIN"
                  "CAP_NET_RAW"
                ];
                CapabilityBoundingSet = [
                  "CAP_NET_ADMIN"
                  "CAP_NET_RAW"
                ];
                DeviceAllow = [ "/dev/net/tun rw" ];
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [
                  "AF_INET"
                  "AF_INET6"
                  "AF_UNIX"
                  "AF_NETLINK"
                  "AF_PACKET"
                ];
                RestrictNamespaces = true;
                LockPersonality = true;
                SystemCallArchitectures = "native";
              };
            };
          };
      };
  };
}
