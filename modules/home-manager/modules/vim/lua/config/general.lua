-- vim.o:  global options
-- vim.bo: buffer-local options
-- vim.wo: window-local options

-- global options
vim.o.autochdir        = true               -- Automatically change the working dir to current file
vim.o.backspace        = "indent,eol,start" -- allow backspacing over everything in insert mode
vim.o.clipboard        = "unnamedplus"      -- Set Clipboard to system's clipboard
vim.o.completeopt      = "menuone,noselect" -- Use popup completion menu for single results aswell
vim.o.foldlevelstart   = 20                 -- start with open folds
vim.o.foldmethod       = "syntax"           -- set folding based on syntax
vim.o.hidden           = true               -- Don't unload buffers when abandoned
vim.o.history          = 50                 -- keep 50 lines of command line history
vim.o.hlsearch         = true               -- highlight matches
vim.o.ignorecase       = true               -- Case insensitive search
vim.o.incsearch        = true               -- search as characters are entered
vim.o.laststatus       = 2                  -- Always show the status line
vim.o.lazyredraw       = true               -- redraw only when we need to.
vim.o.mouse            = "a"                -- Enable mouse in all modes
vim.o.ruler            = true               -- show the cursor position all the time
vim.o.scrolloff        = 5                  -- show lines above and below when scrolling
vim.o.showcmd          = true               -- display incomplete commands
vim.o.smartcase        = true               -- Case sensitive then capital is typed
vim.o.synmaxcol        = 200                -- Maximum length of syntax highlighting
vim.o.title            = true               -- Show title in terminal window
vim.o.wildmenu         = true               -- Complete commands
vim.o.wrapscan         = true               -- Wrap when searching to beginning
vim.o.conceallevel     = 0                  -- Don't ever hide stuff from me
vim.o.inccommand       = "nosplit"          -- Show command effects as you type
vim.o.timeoutlen       = 500                -- " Set timeout, e.g. used in whichkey
vim.g.mapleader        = " "                -- Set mapleader to space
vim.o.cmdheight        = 1                  -- Height of the command section
vim.cmd('filetype plugin indent on')        -- TODO: How do I do this in lua?
vim.cmd('set termguicolors')

-- window-local options
vim.wo.number          = true               -- show absolute line numbers
vim.wo.relativenumber  = true               -- show relative line numbers
vim.wo.cursorline      = true               -- highlight current line

-- Backups/Swapfiles
local tmpdir = vim.fn.expand('$HOME') .. "/.vimtmp"
vim.o.undodir          = tmpdir             -- Dir for undofiles, same dir as the tempdir
vim.o.directory        = tmpdir             -- Dir for temp files
vim.o.backup           = false              -- dont create backups
vim.o.swapfile         = false              -- dont create a swapfile
vim.o.undofile         = true               -- Maintain undo history between sessions

-- Indention
-- TODO look at: https://stackoverflow.com/questions/3682582/how-to-use-only-tab-not-space-in-vim
vim.bo.shiftwidth      = 4                  -- Size of a tab
vim.o.autoindent       = true               -- always set autoindenting on
vim.bo.expandtab       = false              -- Don't expand tabs to spaces
vim.o.softtabstop      = 4                  -- Size of a tab
vim.o.tabstop          = 4                  -- A tab is displayed 4 collumns wide

-- Language specific
vim.g["go_auto_type_info"]     = 1          -- Go:        Show Go type info of variables
vim.g["vim_markdown_conceal"]  = 0          -- Markdown:  Disable concellevel for markdown
vim.g["terraform_align"]       = 1          -- Terraform: Auto-align
vim.g["terraform_fmt_on_save"] = 1          -- Terraform: Format on saving

-- Wrap markdown files to 80 chars per line
vim.cmd('au BufRead,BufNewFile *.md setlocal textwidth=80')

-- TODO translate to lua
-- " Cursor to last know position
-- if has("autocmd")
--         autocmd BufReadPost *
--                                 \ if line("'\"") > 1 && line("'\"") <= line("$") |
--                                 \   exe "normal! g`\"" |
--                                 \ endif
-- endif
