# nix run .\#woodpecker-pipeline
{
  pkgs,
  lib,
  flake-self,
  ...
}:
with pkgs;
let
  supportedSystems = [
    # "aarch64-linux"
    "x86_64-linux"
  ];
  forAllSystems = lib.genAttrs supportedSystems;
  pipelineFor = forAllSystems (
    system:
    writeText "pipeline" (
      builtins.toJSON {
        configs =
          let
            # Map platform names between woodpecker and nix
            woodpecker-platforms = {
              "aarch64-linux" = "linux/arm64";
              "x86_64-linux" = "linux/amd64";
            };
            nixFlakeShowStep = {
              name = "Nix flake show";
              image = "bash";
              commands = [ "nix flake show" ];
            };
            atticSetupStep = {
              name = "Setup Attic";
              image = "bash";
              commands = [
                "attic login lounge-rocks https://cache.lounge.rocks $ATTIC_KEY --set-default"
              ];
              environment = {
                ATTIC_KEY.from_secret = "attic_key";
              };
            };
            nixFastBuildStep = {
              name = "Build all outputs for this architecture";
              image = "bash";
              failure = "ignore";
              commands = [
                ''nix-fast-build --no-nom --skip-cached --attic-cache lounge-rocks:nix-cache --flake ".#checks.$(nix eval --raw --impure --file builtins.currentSystem)"''
              ];
            };
            verifyBuildsStep = {
              name = "Verify all builds succeeded";
              image = "bash";
              commands = [
                ''nix-fast-build --no-nom --skip-cached --flake ".#checks.$(nix eval --raw --impure --file builtins.currentSystem)"''
              ];
            };
          in
          pkgs.lib.lists.flatten [
            (map
              (arch: {
                name = "Hosts with arch: ${arch}";
                data = (
                  builtins.toJSON {
                    labels = {
                      backend = "local";
                      platform = woodpecker-platforms."${arch}";
                    };
                    when = [
                      { event = "manual"; }
                      {
                        event = "push";
                        branch = "main";
                      }
                    ];
                    steps = pkgs.lib.lists.flatten (
                      [ nixFlakeShowStep ]
                      ++ [ atticSetupStep ]
                      ++ [ nixFastBuildStep ]
                      ++ (map (
                        host:
                        # Skip hosts with CISkip set or wrong architecture
                        if
                          flake-self.nixosConfigurations.${host}.config.pinpox.defaults.CISkip
                          || (flake-self.nixosConfigurations.${host}.pkgs.stdenv.hostPlatform.system != arch)
                        then
                          [ ]
                        else
                          [
                            {
                              name = "Build ${host}";
                              image = "bash";
                              failure = "ignore";
                              commands = [
                                "nix build --print-out-paths '.#nixosConfigurations.${host}.config.system.build.toplevel' -o 'result-${host}'"
                              ];
                            }
                            {
                              name = "Show ${host} info";
                              image = "bash";
                              failure = "ignore";
                              commands = [
                                "nix path-info --closure-size -h $(readlink -f 'result-${host}')"
                              ];
                            }
                          ]
                      ) (builtins.attrNames flake-self.nixosConfigurations))
                      ++ [ verifyBuildsStep ]
                    );
                  }
                );
              })
              [
                "${system}"
              ]
            )
          ];
      }
    )
  );
in
pkgs.writeShellScriptBin "woodpecker-pipeline" ''
  # make sure .woodpecker folder exists
  mkdir -p .woodpecker

  # empty content of .woodpecker folder
  rm -rf .woodpecker/*

  # copy pipelines to .woodpecker folder
  ${lib.concatMapStringsSep "\n" (system:
    let
      name = builtins.replaceStrings [ "_" ] [ "-" ] (builtins.head (lib.splitString "-" system));
      arch = builtins.elemAt (lib.splitString "-" system) 1;
    in
    "cat ${pipelineFor.${system}} | ${pkgs.jq}/bin/jq '.configs[].data' -r | ${pkgs.jq}/bin/jq > .woodpecker/${name}-${arch}.yaml"
  ) supportedSystems}
''
