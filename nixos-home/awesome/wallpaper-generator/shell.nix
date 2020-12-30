# Import the nix package collection, so we can access the `pkgs` and `stdenv`
# variables
with import <nixpkgs> {};

# List lua packages sepraterly, so we can get the path in the exports
with luaPackages;
let
  libs = [lua lgi luafilesystem];
in

# Make a new "derivation" that represents our shell
stdenv.mkDerivation rec {
  name = "lua-env";

  # The packages in the `buildInputs` list will be added to the PATH in our shell
  buildInputs = [
    entr
    feh
  ] ++ libs;

  # Export paths and add helper functions and aliases
  shellHook = ''
    export LUA_CPATH="${lib.concatStringsSep ";" (map getLuaCPath libs)}"
    export LUA_PATH="${lib.concatStringsSep ";" (map getLuaPath libs)};$LUA_PATH;$(pwd)/?.lua"

    preview() {
      echo main.lua | entr sh -c 'lua main.lua' &
      feh -F --auto-reload $1
    }

    alias build="lua main.lua"
  '';
}
