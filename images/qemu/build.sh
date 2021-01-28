#!/usr/bin/env bash

GC_DONT_GC=1 nix-build -v '<nixpkgs/nixos>' -A config.system.build.qcow2 --arg configuration "{ imports = [ ./build-qcow2.nix ]; }"
