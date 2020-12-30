{ config, pkgs, lib, ... }:
{
  # nixpkgs.overlays = [
  #   (self: super: {
  #      dwm = super.dwm.overrideAttrs (oa: {
  #        patches = oa.patches ++ [
  #          # ./patch1.patch
  #          (builtins.fetchurl https://dwm.suckless.org/patches/tab/dwm-6.1-pertag-tab-v2b.diff)
  #          # "${builtins.fetchGit https://github.com/owner/dwm-patches}/patch3.patch"
  #        ];
  #      });
  #   })
  # ];
}
