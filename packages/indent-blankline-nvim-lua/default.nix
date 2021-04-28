{ pkgs, stdenv, fetchFromGitHub }:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "indent-blankline-nvim-lua";
  version = "2021-04-23";
  src = fetchFromGitHub {
    owner = "lukas-reineke";
    repo = "indent-blankline.nvim";
    rev = "1bc7d243012aefa0b596c9559f320056e492ebba";
    sha256 = "sha256-VFtbfgTBh2SbrHPNlwUanwlFcHMAZk+sDDnEu0EIsak=";
  };
  meta.homepage = "https://github.com/lukas-reineke/indent-blankline.nvim/";
}

