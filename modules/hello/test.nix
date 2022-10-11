{ pkgs, system, self, ... }:

with import (pkgs + "/nixos/lib/testing-python.nix") { inherit system; };

(makeTest {
  nodes = {
    client = { ... }: {
      imports = [ self.nixosModules.hello ];
      pinpox.services.hello.enable = true;
    };
  };

  testScript = ''
    start_all()
    client.wait_for_unit("multi-user.target")
    print(client.succeed("uname"))
    print(client.succeed("hello"))
  '';
}).test
