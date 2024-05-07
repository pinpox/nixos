{
  pkgs,
  stdenv,
  fetchFromGitHub,
  lib,
  inputs,
  ...
}:
pkgs.vimUtils.buildVimPlugin {
  pname = "nvim-cokeline";
  version = "latest";
  src = inputs.nvim-cokeline;

  meta = with lib; {
    description = "A Neovim bufferline for people with addictive personalities";
    homepage = "https://github.com/noib3/nvim-cokeline";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
