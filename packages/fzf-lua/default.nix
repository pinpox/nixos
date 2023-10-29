{ pkgs, stdenv, fetchFromGitHub, lib, inputs, ... }:
pkgs.vimUtils.buildVimPlugin {
  pname = "fzf-lua";
  version = "latest";
  src = inputs.fzf-lua;

  meta = with lib; {
    description = "Improved fzf.vim written in lua";
    homepage = "https://github.com/ibhagwan/fzf-lua";
    license = licenses.agpl3;
    platforms = platforms.unix;
  };
}

