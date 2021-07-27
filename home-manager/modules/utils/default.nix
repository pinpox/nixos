{ lib, pkgs, ... }:

# let
#   ext = lib.makeExtensible (self:
#     let
#       callLibs = file: import file { inherit lib; inherit pkgs; ext = self; };
#     in with self; {
#       # fn = callLibs ./fn.nix;
#       utils = callLibs ./utils.nix;
#     }
#   );
# in {
#   _module.args = {
#     inherit ext;
#   };
# }

{
  _module.args.utils = import ./utils.nix { inherit pkgs; };
}
