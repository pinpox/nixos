{ pkgs, flake-self, inputs }:


with pkgs; writeText "pipeline" (builtins.toJSON
{
  configs =
    let
      atticSetupStep = {
        name = "Setup Attic";
        image = "bash";
        commands = [
          "attic login lounge-rocks https://cache.lounge.rocks $ATTIC_KEY --set-default"
        ];
        secrets = [ "attic_key" ];
      };
      atticPushStep = {
        name = "Push to Attic";
        image = "bash";
        commands = [
          "attic push lounge-rocks:nix-cache result"
        ];
        secrets = [ "attic_key" ];
      };
    in
    [
      # TODO Show flake info
    ] ++

    # Hosts
    map
      (host: {
        name = "Host: ${host}";
        data = (builtins.toJSON {
          labels.backend = "local";
          pipeline = [
            atticSetupStep
            {
              name = "Build configuration for ${host}";
              image = "bash";
              commands = [
                # "nix build '.#nixosConfigurations.${host}.config.system.build.toplevel'"
                "nix build 'nixpkgs#hello'" # TODO Replace with real command above
              ];
            }
            atticPushStep
          ];
        });
      })
      (builtins.attrNames flake-self.nixosConfigurations) ++

    # Packages
    # Map over architectures. Could optionally be done with woodpecker's
    # matrix build, but we are using nix anyway
    pkgs.lib.lists.flatten (map
      (arch:
        let
          packages = (builtins.attrNames flake-self.packages."${arch}");

          # Map platform names between woodpecker and nix
          woodpecker-platforms = {
            "aarch64-linux" = "linux/arm64";
            "x86_64-linux" = "linux/amd64";
          };
        in

        # Map over all packages of the current architecture.
        (map
          (package: {
            name = "Package: ${package} on ${arch}";
            data = (builtins.toJSON {
              labels.backend = "local";
              platform = woodpecker-platforms."${arch}";
              pipeline = [
                atticSetupStep
                {
                  name = "Build package ${package}";
                  image = "bash";
                  commands = [
                    # "nix build '.#nixosConfigurations.${host}.config.system.build.toplevel'"
                    "nix build 'nixpkgs#hello'" # TODO replace with real command
                    "attic push lounge-rocks:nix-cache result"
                  ];
                }
              ];
            });
          })
          packages))
      (builtins.attrNames flake-self.packages)) ++
    [
      # TODO Send notification
    ];
})
