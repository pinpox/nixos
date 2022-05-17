{ pkgs
, stdenv
, fetchFromGitHub
, lib
, inputs
, ...
}:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "zk-nvim";
  version = "latest";
  src = inputs.zk-nvim;

  meta = with lib; {
    description = "Neovim plugin as a lightweight wrapper around zk";
    homepage = "https://github.com/megalithic/zk.nvim";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
