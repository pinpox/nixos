{ self, config, pkgs, lib, ... }:
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
    vscode-extensions.golang.Go # Golang snippets
    gopls # LSP go
    terraform-ls # LSP terraform
    terraform # TODO add options to enable/disable large packages like terraform
    libgccjit # Needed for treesitter
  ];

  xdg = {
    enable = true;
    configFile = {

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
      nvim_lua_nixcolors = {
        target = "nvim/lua/nixcolors.lua";
        text = ''
          local M =  {}

          M.Black         = "#${vars.colors.Black}"
          M.DarkGrey      = "#${vars.colors.DarkGrey}"
          M.Grey          = "#${vars.colors.Grey}"
          M.BrightGrey    = "#${vars.colors.BrightGrey}"
          M.DarkWhite     = "#${vars.colors.DarkWhite}"
          M.White         = "#${vars.colors.White}"
          M.BrightWhite   = "#${vars.colors.BrightWhite}"
          M.DarkRed       = "#${vars.colors.DarkRed}"
          M.Red           = "#${vars.colors.Red}"
          M.BrightRed     = "#${vars.colors.BrightRed}"
          M.DarkYellow    = "#${vars.colors.DarkYellow}"
          M.Yellow        = "#${vars.colors.Yellow}"
          M.BrightYellow  = "#${vars.colors.BrightYellow}"
          M.DarkGreen     = "#${vars.colors.DarkGreen}"
          M.Green         = "#${vars.colors.Green}"
          M.BrightGreen   = "#${vars.colors.BrightGreen}"
          M.DarkCyan      = "#${vars.colors.DarkCyan}"
          M.Cyan          = "#${vars.colors.Cyan}"
          M.BrightCyan    = "#${vars.colors.BrightCyan}"
          M.DarkBlue      = "#${vars.colors.DarkBlue}"
          M.Blue          = "#${vars.colors.Blue}"
          M.BrightBlue    = "#${vars.colors.BrightBlue}"
          M.DarkMagenta   = "#${vars.colors.DarkMagenta}"
          M.Magenta       = "#${vars.colors.Magenta}"
          M.BrightMagenta = "#${vars.colors.BrightMagenta}"

          return M

        '';
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
      require('config.treesitter')
      require('config.lsp')
      require('config.devicons')
      require('config.compe')
      require('config.which-key')
      require('config.bufferline')
      require('config.lualine')
      require('config.gitsigns')

      EOF

      " Add snippet directories from packages
      let g:vsnip_snippet_dirs = ['${pkgs.vscode-extensions.golang.Go}/share/vscode/extensions/golang.Go/snippets/']

    '';

    # loaded on launch
    plugins = with pkgs.vimPlugins; [

      (pkgs.callPackage ../../../packages/indent-blankline-nvim-lua { })

      # TODO Submit PR to add to nixpkgs
      (plugin "colorbuddy.nvim" "tjdevries/colorbuddy.nvim" "master"
        "87c80e3f4a590d0387d9b128d1f1fc456759408a")

      # TODO Submit PR to update in nixpkgs. Support for expr mappings was
      # added in this commit
      (plugin "which-key-nvim" "folke/which-key.nvim" "main"
        "9d2785c4d44b4a8ca1095856cb4ee34a32497cf6")


      friendly-snippets
      nvim-treesitter
      BufOnly-vim
      ansible-vim
      base16-vim
      committia-vim
      fzf-vim
      gitsigns-nvim
      gotests-vim
      haskell-vim
      i3config-vim
      lualine-nvim
      nvim-bufferline-lua
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
      vim-grammarous
      vim-gutentags
      vim-illuminate
      vim-indent-object
      vim-markdown
      # which-key-nvim
      # TODO include when nixpkgs is merged (commit after 2021-05-13)
      vim-nix
      vim-repeat
      vim-sandwich
      vim-snippets
      vim-table-mode
      vim-terraform
      vim-textobj-user
      vim-vinegar
      vim-visual-increment
      vim-vsnip
      vim-gnupg
      vim-vsnip-integ
      vista-vim
    ];
  };
}

# TODO Missing plugins
# autopairs
# fvictorio/vim-textobj-backticks'
# nicwest/vim-camelsnek'
# thinca/vim-textobj-between'           "Text objects for a range between a character
# timakro/vim-searchant'                " Better highlighting of search
