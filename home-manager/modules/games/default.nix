{ config, pkgs, lib, ... }: {
  nixpkgs.config.retroarch = {
    # All available cores can be found here:
    # https://github.com/NixOS/nixpkgs/pull/82633/files#diff-036410e9211b4336186fc613f7200b12
    enableBeetleLynx = true;
    enableBeetlePCEFast = true;
    enableBeetlePCFX = true;
    enableBeetlePSX = true;
    enableBeetlePSXHW = true;
    enableBeetleSNES = true;
    # enableBeetleSaturn = true;
    # enableBeetleSaturnHW = true;
    # enableBeetleSuperGrafx = true;
    # enableDolphin = true;
    enableGenesisPlusGX = true;
    # enableMAME = true;
    enableMBGA = true;
    enableMGBA = true;
    enableMupen64Plus = true;
    enablePCSXRearmed = true;
    enableParallelN64 = true;
    enableQuickNES = true;
    enableSnes9x = true;
    enableVbaM = true;
  };
}
