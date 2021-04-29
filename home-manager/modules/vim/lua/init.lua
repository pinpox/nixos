-- vim.o:  global options
-- vim.bo: buffer-local options
-- vim.wo: window-local options

-- global options
vim.o.autochdir        = true               -- Automatically change the working dir to the one of the file
vim.o.backspace        = "indent,eol,start" -- allow backspacing over everything in insert mode
vim.o.clipboard        = "unnamedplus"      -- Set Clipboard to system's clipboard
vim.o.completeopt      = "menuone,noselect"
vim.o.foldlevelstart   = 20                 -- start with open folds
vim.o.foldmethod       = "syntax"           -- set folding based on syntax
vim.o.hidden           = true               -- Buffer becomes hidden when it is abandoned but is not unloaded
vim.o.history          = 50                 -- keep 50 lines of command line history
vim.o.hlsearch         = true               -- highlight matches
vim.o.ignorecase       = true               -- Case insensitive search
vim.o.incsearch        = true               -- search as characters are entered
vim.o.laststatus       = 2                  -- Always show the status line
vim.o.lazyredraw       = true               -- redraw only when we need to.
vim.o.mouse            = "a"
vim.o.ruler            = true               -- show the cursor position all the time
vim.o.scrolloff        = 5                  -- show lines above and below when scrolling
vim.o.showcmd          = true               -- display incomplete commands
vim.o.smartcase        = true               -- Case sensitive then capital is typed
vim.o.synmaxcol        = 200                -- Maximum length of syntax highlighting
vim.o.title            = true               -- Show title in terminal window
vim.o.wildmenu         = true               -- Complete commands
vim.o.wrapscan         = true               -- Wrap when searching to beginning

-- Backups/Swapfiles
local tmpdir = vim.fn.expand('$HOME') .. "/.vimtmp"

vim.o.undodir          = tmpdir             -- Dir for undofiles, same dir as the tempdir
vim.o.directory        = tmpdir             -- Dir for temp files
vim.o.backup           = false              -- dont create backups
vim.o.swapfile         = false              -- dont create a swapfile
vim.o.undofile         = true               -- Maintain undo history between sessions

-- window-local options
vim.wo.number          = true               -- show absolute line numbers
vim.wo.relativenumber  = true               -- show relative line numbers
vim.wo.cursorline      = true               -- highlight current line

-- Indention
vim.o.shiftwidth       = 4                  -- Size of a tab
vim.o.autoindent       = true               -- always set autoindenting on
vim.bo.expandtab       = false              -- Don't expand tabs to spaces
vim.o.softtabstop      = 4                  -- Size of a tab
vim.o.tabstop          = 4                  -- A tab is displayed 4 collumns wide



-- Plugin variables
-- Arduino
vim.g.arduino_programmer =  'arduino:avrispmkii'
vim.g.arduino_dir = '/usr/share/arduino'
vim.g.arduino_args = '--verbose-upload'


-- Markdown
-- the browser to use for preview
vim.g.livedown_browser = "firefox"

-- Fzf, show file preview
vim.g.fzf_files_options = '--preview "(coderay {} || cat {}) 2> /dev/null | head -\'.&lines.\'"'


vim.g.indentLine_char = '│'


require('config.lsp')
require('config.devicons')
require('config.compe')
require('config.which-key')
require('config.bufferline')
require('config.lualine')
require('config.gitsigns')

