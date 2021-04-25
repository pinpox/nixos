{ self, config, pkgs, lib, ... }:
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


    xdg = {
      enable = true;
      configFile = {
        nvim_lua = {
          target = "nvim/lua";
          source = ./lua;
        };

        nvim_vimscript = {
          target = "nvim/vimscript";
          source = ./vimscript;
        };
      };
    };



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

      # FILE BROWSING:
      (lib.strings.fileContents ./vimscript/netrw.vim)

      # APPEARANCE:
      (lib.strings.fileContents ./vimscript/style.vim)

      # TODO
      # https://github.com/windwp/nvim-autopairs

      ''

        filetype plugin indent on
        syntax enable                  " enable syntax highlighting
        set conceallevel=0             " Don't ever hide stuff from me



        " let g:go_auto_type_info = 1 "Show Go type info of variables
        au FileType xml setlocal equalprg=xmllint\ --format\ --recover\ -\ 2>/dev/null "autoindent xml correctly
        au BufRead,BufNewFile *.md setlocal textwidth=80 " Wrap markdown files to 80 chars per line
        let g:tex_flavor = "latex"

        " Cursor to last know position
        if has("autocmd")
            autocmd BufReadPost *
                        \ if line("'\"") > 1 && line("'\"") <= line("$") |
                        \   exe "normal! g`\"" |
                        \ endif
        endif


        lua << EOF

        ${lib.strings.fileContents ./lua/init.lua}

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

      (pkgs.callPackage ../../../packages/indent-blankline-nvim-lua { })

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
      neuron-vim
      BufOnly-vim
      lualine-nvim
      ansible-vim
      base16-vim
      fzf-vim
      vista-vim
      gotests-vim
      haskell-vim
      i3config-vim
      # indentLine
      # indent-blankline-nvim
      tabular
      vim-autoformat
      vim-better-whitespace
      vim-commentary
      vim-devicons
      vim-easy-align
      vim-eunuch
      # vim-gitgutter
      plenary-nvim
      gitsigns-nvim
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
      nvim-bufferline-lua
      nvim-web-devicons
      #vista-vim
    ];
  };
}

# TODO Missing plugins
# AndrewRadev/switch.vim'
# fvictorio/vim-textobj-backticks'
# jamessan/vim-gnupg', {'for': 'gpg'}   " Edit ggp-encrypted files
# juliosueiras/vim-terraform-snippets'
# nicwest/vim-camelsnek'
# prabirshrestha/async.vim'
# rafalbromirski/vim-aurora'
# rrethy/vim-hexokinase'
# stevearc/vim-arduino'
# thinca/vim-textobj-between'           "Text objects for a range between a character
# timakro/vim-searchant'                " Better highlighting of search
