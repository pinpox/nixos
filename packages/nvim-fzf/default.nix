{ pkgs, stdenv, fetchFromGitHub, lib, inputs, ... }:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "nvim-fzf";
  version = "latest";
  src = inputs.nvim-fzf;

  meta = with lib; {
    description = "A Lua API for using fzf in neovim";
    homepage = "https://github.com/vijaymarupudi/nvim-fzf";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}

