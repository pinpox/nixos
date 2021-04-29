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


require'compe'.setup {
	enabled = true;
	autocomplete = true;
	debug = false;
	min_length = 1;
	preselect = 'enable';
	throttle_time = 80;
	source_timeout = 200;
	incomplete_delay = 400;
	max_abbr_width = 100;
	max_kind_width = 100;
	max_menu_width = 100;
	documentation = true;

	source = {
		path = true;
		emoji = true;
		buffer = true;
		calc = true;
		vsnip = true;
		nvim_lsp = true;
		nvim_lua = true;
		spell = true;
		tags = true;
		snippets_nvim = true;
		treesitter = true;
	};
}


local t = function(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
	local col = vim.fn.col('.') - 1
	if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
		return true
	else
		return false
	end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
	if vim.fn.pumvisible() == 1 then
		return t "<C-n>"
	elseif vim.fn.call("vsnip#available", {1}) == 1 then
		return t "<Plug>(vsnip-expand-or-jump)"
	elseif check_back_space() then
		return t "<Tab>"
	else
		return vim.fn['compe#complete']()
	end
end
_G.s_tab_complete = function()
	if vim.fn.pumvisible() == 1 then
		return t "<C-p>"
	elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
		return t "<Plug>(vsnip-jump-prev)"
	else
		return t "<S-Tab>"
	end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})



require'lspconfig'.pyright.setup{}
require'lspconfig'.gopls.setup{}
require'lspconfig'.terraformls.setup{}
require'lspconfig'.bashls.setup{}
require'lspconfig'.yamlls.setup{}

require'lspconfig'.jsonls.setup {

	cmd = { "json-languageserver", "--stdio" },
	commands = {
		Format = {
			function()
				vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
			end
		}
	}
}

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


require'bufferline'.setup{
	options = {
		numbers =  "ordinal",
		number_style = "normal",
		mappings = true, --  <leader>1-9 mappings to navigate tabs
		buffer_close_icon= '',
		modified_icon = '●',
		close_icon = '',
		left_trunc_marker = '',
		right_trunc_marker = '',
		max_name_length = 18,
		max_prefix_length = 15, -- prefix used when a buffer is deduplicated
		tab_size = 18,
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level, diagnostics_dict)
			return "("..count..")"
		end,
		-- NOTE: this will be called a lot so don't do any heavy processing here
		-- custom_filter = function(buf_number)
		--   -- filter out filetypes you don't want to see
		--   if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
		--     return true
		--   end
		--   -- filter out by buffer name
		--   if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
		--     return true
		--   end
		--   -- filter out based on arbitrary rules
		--   -- e.g. filter out vim wiki buffer from tabline in your work repo
		--   if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
		--     return true
		--   end
		-- end,
		show_buffer_close_icons = true,
		show_close_icon = true,
		show_tab_indicators = true,
		persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
		-- can also be a table containing 2 custom separators
		-- [focused and unfocused]. eg: { '|', '|' }
		separator_style = "slant", --| "thick" | "thin" | { 'any', 'any' },
		enforce_regular_tabs = false , --| true,
		always_show_bufferline = true, --, | false,
		-- sort_by =  function(buffer_a, buffer_b)
		--   -- add custom logic
		--   return buffer_a.modified > buffer_b.modified
		-- end
	},
}

require'nvim-web-devicons'.setup {
	-- globally enable default icons (default to false)
	-- will get overriden by `get_icons` option
	default = true;
}

require('mappings')
require('evil_lualine')

require('which-key').setup {}

require('gitsigns').setup {
	signs = {

		-- copy from : https://en.wikipedia.org/wiki/Box-drawing_character
		add          = {hl = 'GitSignsAdd'   , text = '┃', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
		change       = {hl = 'GitSignsChange', text = '┇', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
		delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
		topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
		changedelete = {hl = 'GitSignsChange', text = '┇', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
	},
	numhl = false,
	linehl = false,
	keymaps = {
		-- Default keymap options
		noremap = true,
		buffer = true,

		['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
		['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},

		['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
		['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
		['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
		['n <leader>hR'] = '<cmd>lua require"gitsigns".reset_buffer()<CR>',
		['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
		['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>',

		-- Text objects
		['o ih'] = ':<C-U>lua require"gitsigns".select_hunk()<CR>',
		['x ih'] = ':<C-U>lua require"gitsigns".select_hunk()<CR>'
	},
	watch_index = {
		interval = 1000
	},
	current_line_blame = false,
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	use_decoration_api = true,
	use_internal_diff = true,  -- If luajit is present
}
