{ self, config, pkgs, lib, utils, ... }:
let
  vars = import ../vars.nix;

  # Helper function to add plugins directly from GitHub if they are not
  # packaged in nixpkgs yet
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
    vscode-extensions.golang.go # Golang snippets
    gopls # LSP go
    terraform-ls # LSP terraform
    terraform # TODO add options to enable/disable large packages like terraform
    libgccjit # Needed for treesitter
    sumneko-lua-language-server # Lua language server

    cargo
    rustc
    rustfmt
    rust-analyzer
  ];

  xdg = {
    enable = true;
    configFile = {

      nixcolors-lua = {
        target = "nvim/lua/nixcolors.lua";
        source = utils.renderMustache "nixcolors.lua" ./nixcolors.lua.mustache
          vars.colors;
      };

      nvim_lua_config = {
        target = "nvim/lua/config";
        source = ./lua/config;
      };

      nvim_lua_utils = {
        target = "nvim/lua/utils";
        source = ./lua/utils;
      };

      colors = {
        target = "nvim/colors/generated.vim";
        text = ''" File empty on purpouse'';
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
    withPython3 = true;
    withRuby = true;

    extraConfig = ''
      lua << EOF

      local utils = require('utils')

      require('config.general') -- General options, should stay first!
      require('config.pinpox-colors')
      require('config.appearance')
      -- require('config.treesitter')
      require('config.lsp')
      require('config.devicons')
      require('config.compe')
      require('config.which-key')
      require('config.bufferline')
      require('config.lualine')
      require('config.gitsigns')
      require('config.zk')

      EOF

      " Add snippet directories from packages
      let g:vsnip_snippet_dirs = ['${pkgs.vscode-extensions.golang.go}/share/vscode/extensions/golang.Go/snippets/']

    '';

    # loaded on launch
    plugins = with pkgs.vimPlugins; [

      #      nvim-treesitter
      zk-nvim
      nvim-fzf
      indent-blankline-nvim-lua
      colorbuddy-nvim
      BufOnly-vim
      friendly-snippets
      ansible-vim
      lspsaga-nvim
      base16-vim
      committia-vim
      fzf-vim
      gitsigns-nvim
      gotests-vim
      haskell-vim
      i3config-vim
      lualine-nvim
      bufferline-nvim
      nvim-compe
      nvim-colorizer-lua
      nvim-lspconfig
      nvim-web-devicons
      plenary-nvim
      tabular
      vim-autoformat
      vim-better-whitespace
      vim-commentary
      vim-devicons
      vim-easy-align
      vim-eunuch
      vim-go
      vim-gutentags
      vim-illuminate
      # vim-indent-object
      # vim-markdown # Disabled because of https://github.com/plasticboy/vim-markdown/issues/461
      which-key-nvim
      vim-nix
      vim-repeat
      vim-sandwich
      vim-table-mode
      vim-terraform
      vim-textobj-user
      vim-vinegar
      # vim-visual-increment
      vim-vsnip
      vim-gnupg
      vim-vsnip-integ
    ];
  };
}

# TODO Missing plugins
# TODO use flake inputs for this, if needed
# autopairs
# fvictorio/vim-textobj-backticks'
# nicwest/vim-camelsnek'
# thinca/vim-textobj-between'           "Text objects for a range between a character
# timakro/vim-searchant'                " Better highlighting of search
