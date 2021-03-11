with import <nixpkgs> { };
let
  eval = import (pkgs.path + "/nixos/lib/eval-config.nix") { modules = [ ./hello.nix ../modules/wireguard-client.nix]; };
  opts = (nixosOptionsDoc { options = eval.options; }).optionsJSON;
in runCommandLocal "options.json" { inherit opts; }
"cat $opts/share/doc/nixos/options.json | ${pkgs.jq}/bin/jq '.| with_entries( select(.key|contains(\"pinpox\") ) )' > $out"


