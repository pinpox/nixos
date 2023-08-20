{ pkgs, flake-self, inputs }:

# TODO
# Build hosts
# Build packages
# Show flake info
# Send notificatoin

with pkgs; writeText "pipeline" (builtins.toJSON
{
  configs =
    let
      atticSetupStep = {
        name = "Setup Attic";
        image = "bash";
        commands = [
          "attic login lounge-rocks https://attic.lounge.rocks $ATTIC_KEY --set-default"
        ];
        secrets = [ "attic_key" ];
      };
    in

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
                "nix build 'nixpkgs#hello'"
                "attic push lounge-rocks:lounge-rocks result"
              ];
            }
          ];
        });
      })
      (builtins.attrNames flake-self.nixosConfigurations);
  #++

  # Packages
  # map
  #   (package: {
  #     name = "Package: ${package}";
  #     data = (builtins.toJSON {
  #       labels.backend = "local";
  #       pipeline = [
  #         atticSetupStep
  #         {
  #           name = "Build package ${package}";
  #           image = "bash";
  #           commands = [
  #             # "nix build '.#nixosConfigurations.${host}.config.system.build.toplevel'"
  #             "nix build 'nixpkgs#hello'"
  #             "attic push lounge-rocks:lounge-rocks result"
  #           ];
  #         }
  #       ];
  #     });
  #   })
  #   (builtins.attrNames flake-self.packages);

  # [
  #   {
  #     name = "Host: ${host}";
  #     data = (builtins.toJSON {
  #       labels.backend = "local";
  #       pipeline = [
  #         {
  #           name = "Setup Attic";
  #           image = "bash";
  #           commands = [
  #             "attic login lounge-rocks https://attic.lounge.rocks $ATTIC_KEY --set-default"
  #           ];
  #           secrets = [ "attic_key" ];
  #         }
  #         {
  #           name = "Build configuration for ${host}";
  #           image = "bash";
  #           commands = [
  #             # "nix build '.#nixosConfigurations.${host}.config.system.build.toplevel'"
  #             "nix build 'nixpkgs#hello'"
  #             "attic push lounge-rocks:lounge-rocks result"
  #           ];
  #         }
  #       ];
  #     });
  #   }
  # ];
})

# {
#   name = "Exec pipeline";
#   data = (builtins.toJSON {
#     labels.backend = "local";
#     platform = "linux/arm64";
#     steps.build = {
#       image = "bash";
#       commands = [
#         ''echo "This is the build step"''
#       ];
#     };
#   });
# }
# {
#   name = "Pipeline from string";
#   data = ''
#     {
#       "labels": {
#         "backend": "local"
#       },
#       "pipeline": [
#         {
#           "commands": [
#             "attic login lounge-rocks https://attic.lounge.rocks $ATTIC_KEY --set-default"
#           ],
#           "image": "bash",
#           "name": "Setup Attic",
#           "secrets": [
#             "attic_key"
#           ]
#         },
#         {
#           "commands": [
#             "nix build 'nixpkgs#hello'",
#             "attic push lounge-rocks:lounge-rocks result"
#           ],
#           "image": "bash",
#           "name": "Build and push hello-world"
#         }
#       ]
#     }
#   '';
# })
