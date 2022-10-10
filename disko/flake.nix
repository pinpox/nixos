{
  description = "Disko flake example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:pinpox/disko";

    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, ... }@inputs:
    with inputs;

    (flake-utils.lib.eachDefaultSystem)
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # TODO this should not be neccessary, if disko's flake exposes the
          # package
          disko-package = pkgs.callPackage disko { };
          cfg-laptop = {
            disk = {
              sda = {
                device = "$1";
                type = "device";
                content = {
                  type = "table";
                  format = "msdos";
                  partitions = [
                    {
                      name = "root";
                      type = "partition";
                      part-type = "primary";
                      start = "1M";
                      end = "100%";
                      bootable = true;
                      content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                      };
                    }
                  ];
                };
              };
            };
          };
          # TODO just for testing, add real config that differs from laptop config
          cfg-server = cfg-laptop;
        in
        rec {

          packages = flake-utils.lib.flattenTree {
            laptop = pkgs.writeScriptBin "laptop" (disko-package.create cfg-laptop);
            server = pkgs.writeScriptBin "server" (disko-package.create cfg-server);
          };

          apps = {
            # TODO fails because it does not find parted
            format-laptop = flake-utils.lib.mkApp { drv = packages.laptop; };
            format-server = flake-utils.lib.mkApp { drv = packages.server; };
          };
        });
}
