{ pkgs, flake-self, inputs }:


with pkgs; writeText "pipeline" (builtins.toJSON
{
  configs = [

    {
      name = "Build and push hello-world";
      data = (builtins.toJSON {
        labels.backend = "local";
        pipeline = [
          # {
          #   name = "Setup Attic";
          #   image = "bash";
          #   commands = [
          #     "attic login lounge-rocks https://attic.lounge.rocks $ATTIC_KEY --set-default"
          #   ];
          #   secrets = [ "attic_key" ];
          # }
          {
            name = "Build and push hello-world";
            image = "bash";
            commands = [
              "nix build 'nixpkgs#hello'"
              # "attic push lounge-rocks:lounge-rocks result"
            ];
          }
        ];
      });
    }
  ];
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
#   name = "Pipeline from tring";
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
