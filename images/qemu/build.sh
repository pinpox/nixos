#!/usr/bin/env bash

nix-build '<nixpkgs/nixos>' -A config.system.build.qcow2 --arg configuration "{ imports = [ ./build-qcow2.nix ]; }"
