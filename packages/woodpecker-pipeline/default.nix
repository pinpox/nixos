# To get a valid pipeline as .yml run:
# cat result | jq '.configs[].data' -r | jq
{
  pkgs,
  flake-self,
  inputs,
}:
with pkgs;
writeText "pipeline" (
  builtins.toJSON {
    configs =
      let
        # Map platform names between woodpecker and nix
        # woodpecker-platforms = {
        #   "aarch64-linux" = "linux/arm64";
        #   "x86_64-linux" = "linux/amd64";
        # };
        atticSetupStep = {
          name = "Setup Attic";
          image = "bash";
          commands = [ "attic login lounge-rocks https://cache.lounge.rocks $ATTIC_KEY --set-default" ];
          secrets = [ "attic_key" ];
        };
        mkAtticPushStep = output: {
          name = "Push ${output} to Attic";
          image = "bash";
          commands = [ "attic push lounge-rocks:nix-cache '${output}'" ];
          secrets = [ "attic_key" ];
        };
      in
      [
        # TODO Show flake info
      ]
      ++

        # Hosts
        pkgs.lib.lists.flatten ([
          (map
            (arch: {
              name = "Hosts with arch: ${arch}";
              data = (
                builtins.toJSON {

                  labels.backend = "local";
                  # platform = woodpecker-platforms."${flake-self.nixosConfigurations.${host}.config.nixpkgs.system}";
                  steps = pkgs.lib.lists.flatten (
                    [ atticSetupStep ]
                    ++ (map (
                      host:
                      if
                        # Skip hosts with this option set
                        flake-self.nixosConfigurations.${host}.config.pinpox.defaults.CISkip
                      then
                        [ ]
                      else
                        [
                          {
                            name = "Build configuration for ${host}";
                            image = "bash";
                            commands = [
                              "nix build '.#nixosConfigurations.${host}.config.system.build.toplevel' -o 'result-${host}'"
                            ];
                          }
                          (mkAtticPushStep "result-${host}")
                        ]
                    ) (builtins.attrNames flake-self.nixosConfigurations))
                  );
                }
              );
            })
            [
              # "aarch64-linux"
              "x86_64-linux"
            ]
          )
        ])
      ++

        # Packages
        # Map over architectures. Could optionally be done with woodpecker's
        # matrix build, but we are using nix anyway
        pkgs.lib.lists.flatten (
          map
            (
              arch:
              let
                packages = (builtins.attrNames flake-self.packages."${arch}");
              in

              # Map over all packages of the current architecture.
              (map (package: {
                name = "Package: ${package} on ${arch}";
                data = (
                  builtins.toJSON {
                    labels.backend = "local";
                    # platform = woodpecker-platforms."${arch}";
                    steps = [
                      atticSetupStep
                      {
                        name = "Build package ${package}";
                        image = "bash";
                        group = "packages";
                        commands = [ "nix build '.#${package}' -o 'result-${package}'" ];
                      }
                      (mkAtticPushStep "result-${package}")
                    ];
                  }
                );
              }) packages)
            )
            # TODO Re-Enable all architectures when we have runners for them
            [ "x86_64-linux" ] # (builtins.attrNames flake-self.packages)
        )
      ++ [
        # TODO Send notification
      ];
  }
)
