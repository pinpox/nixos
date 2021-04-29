{ pkgs, stdenv, fetchFromGitHub }:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "which-key";
  version = "2021-04-29";
  src = fetchFromGitHub {
    owner = "folke";
    repo = "which-key.nvim";
    rev = "060a574c228433e9b17960fa0eafca0a975381e8";
    sha256 = "sha256-VFtbfgTBh2SbrHPNlwUanwlFcHMAZk+sDDnEu0EIsak=";
  };
  meta.homepage = "https://github.com/folke/which-key.nvim";
}

