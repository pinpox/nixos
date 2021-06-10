{ pkgs, stdenv, fetchFromGitHub, inputs }:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "indent-blankline-nvim-lua";
  version = "2021-04-23";

  src = inputs.indent-blankline-nvim-lua;
  meta.homepage = "https://github.com/lukas-reineke/indent-blankline.nvim/";
}

