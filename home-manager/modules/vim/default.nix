{ config, pkgs, lib, ... }:
let
  vars = import ./vars.nix;

  plugin = name: repo: branch: sha256:
    pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-plugin-${name}";
      version = "git";
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = branch;
        rev = sha256;
      };
    };

in {

  home.packages = with pkgs; [
    nodePackages.pyright # LSP python
    nodePackages.yaml-language-server # LSP yaml
    nodePackages.vscode-json-languageserver-bin # LSP json
    vscode-extensions.golang.Go # Golang snippets
    gopls # LSP go
    terraform-ls # LSP terraform
    terraform # TODO add options to enable/disable large packages like terraform
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython = true;
    withPython3 = true;
    withRuby = true;

    extraConfig = builtins.concatStringsSep "\n" [

      # PLUGINS:
      (lib.strings.fileContents ./vimscript/plugins.vim)

      # GENERAL OPTIONS:
      (lib.strings.fileContents ./vimscript/general.vim)

      # FILE BROWSING:
      (lib.strings.fileContents ./vimscript/netrw.vim)

      # APPEARANCE:
      (lib.strings.fileContents ./vimscript/style.vim)

      # TODO
      # https://github.com/windwp/nvim-autopairs

      ''

        lua << EOF

        ${lib.strings.fileContents ./lua/init.lua}

        -- KEY MAPPINGS:
        ${lib.strings.fileContents ./lua/mappings.lua}

        ${lib.strings.fileContents ./lua/which-key.lua}

        EOF

        ${lib.strings.fileContents ./vimscript/lsp-config.vim}

        " Add snippet directories from packages
        let g:vsnip_snippet_dirs = ['${pkgs.vscode-extensions.golang.Go}/share/vscode/extensions/golang.Go/snippets/']

        inoremap <silent><expr> <C-Space> compe#complete()
        inoremap <silent><expr> <CR>      compe#confirm('<CR>')
        inoremap <silent><expr> <C-e>     compe#close('<C-e>')
        inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
        inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
      ''

    ];

    # loaded on launch
    plugins = with pkgs.vimPlugins; [

      # TODO Remove when PR is merged https://github.com/NixOS/nixpkgs/pull/117813
      # (plugin "nvim-whichkey-setup.lua" "AckslD/nvim-whichkey-setup.lua" "main"
      #   "59aa0a4287adf6c2c9faabf912cdc005230e7c98")

      vim-nix
      nvim-whichkey-setup-lua
      # vim-indent-guides
      # vimpreviewpandoc
      nvim-compe
      nvim-lspconfig
      vim-vsnip
      vim-vsnip-integ
      # nvim-treesitter

      colorizer
      committia-vim
      BufOnly-vim
      ansible-vim
      base16-vim
      fzf-vim
      vista-vim
      gotests-vim
      haskell-vim
      i3config-vim
      indentLine
      tabular
      vim-airline
      vim-airline-themes
      vim-autoformat
      vim-better-whitespace
      vim-commentary
      vim-devicons
      vim-easy-align
      vim-eunuch
      vim-gitgutter
      vim-go
      vim-grammarous
      vim-gutentags
      vim-illuminate
      vim-indent-object
      vim-markdown
      vim-repeat
      vim-sandwich
      vim-snippets
      vim-table-mode
      vim-terraform
      vim-textobj-user
      vim-vinegar
      vim-visual-increment
      vim-which-key
      #vista-vim
    ];
  };
}

# TODO Missing plugins
# AndrewRadev/switch.vim'
# fvictorio/vim-textobj-backticks'
# jamessan/vim-gnupg', {'for': 'gpg'}   " Edit ggp-encrypted files
# juliosueiras/vim-terraform-snippets'
# lukas-reineke/indent-blankline.nvim'
# nicwest/vim-camelsnek'
# prabirshrestha/async.vim'
# rafalbromirski/vim-aurora'
# rrethy/vim-hexokinase'
# stevearc/vim-arduino'
# thinca/vim-textobj-between'           "Text objects for a range between a character
# timakro/vim-searchant'                " Better highlighting of search
