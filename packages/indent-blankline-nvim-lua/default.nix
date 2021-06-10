{ pkgs, stdenv, fetchFromGitHub, inputs,... }:
pkgs.vimUtils.buildVimPluginFrom2Nix {
  pname = "indent-blankline-nvim-lua";
  version = "latest";
  src = inputs.indent-blankline-nvim-lua;

  meta = with lib; {
    description = "Indent guides for Neovim";
    homepage = "https://github.com/lukas-reineke/indent-blankline.nvim/";
    # license = licenses.mit;
    platforms = platforms.unix;
  };
}

