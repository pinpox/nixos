{ ... }:
{
  _class = "clan.service";
  manifest.name = "localsend";
  manifest.description = "Local network file sharing application";
  manifest.readme = "Local network file sharing application";
  manifest.categories = [ "Utility" ];

  roles.default = {
    description = "Sets up localsend";
    interface =
      { lib, ... }:
      {
        options = {
          displayName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "The name that localsend will use to display your instance.";
          };

          ipv4Addr = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "192.168.56.2/24";
            description = "Optional IPv4 address for ZeroTier network. Only needed until IPv6 multicasting is supported.";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      {
        nixosModule =
          {
            pkgs,
            lib,
            ...
          }:
          {

            config = {

              clan.core.state.localsend.folders = [ "/var/localsend" ];

              environment.systemPackages =
                let
                  localsend-ensure-config = pkgs.writers.writePython3Bin "localsend-ensure-config" {
                  } ./localsend-ensure-config.py;

                  localsend = pkgs.writeShellScriptBin "localsend" ''
                    set -xeu
                    ${lib.getExe localsend-ensure-config} ${
                      lib.optionalString (settings.displayName != null) settings.displayName
                    }
                    ${lib.getExe pkgs.localsend}
                  '';
                in
                [ localsend ];

              networking.firewall.allowedTCPPorts = [ 53317 ];

              # This is currently needed because there is no ipv6 multicasting support yet
              systemd.network.networks = lib.mkIf (settings.ipv4Addr != null) {
                "09-zerotier" = {
                  networkConfig = {
                    Address = settings.ipv4Addr;
                  };
                };
              };
            };
          };
      };
  };
}
