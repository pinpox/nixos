local wk = require("which-key")
wk.setup {
	plugins = {
		registers = true, -- Show registers and macros on " and @
		-- spelling = {
		--     enabled = true, -- z= to select spelling suggestions
		--     suggestions = 5,
		-- },
	},
}

-----------------
-- Normal mode --
-----------------

wk.register({

	-- Leader key
	["<leader>"] = {

		-- FZF
		F = { ':FzfLua git_files<CR>',  'Git files' },
		f = { ':FzfLua files<CR>',   'Files' },
		b = { ':FzfLua buffers<CR>', 'Buffers' },

		r = { ':lua vim.lsp.buf.rename()<CR>', "Rename" },

		h = {
			name = "Help",
			h = { ':lua vim.lsp.buf.hover()<CR>',                        'Hover information' },
			s = { ':lua vim.lsp.buf.signature_help()<CR>',               'Signature' },
			l = { ':lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', 'Line diagnostics' },
			g = { ':lua require"gitsigns".blame_line()<CR>',             'Git Blame line' },
		},

		g = {
			name = "Git",
			s = { ':lua require"gitsigns".stage_hunk()<CR>',      'Stage hunk' },
			u = { ':lua require"gitsigns".undo_stage_hunk()<CR>', 'Undo stage hunk' },
			r = { ':lua require"gitsigns".reset_hunk()<CR>',      'Reset hunk' },
			R = { ':lua require"gitsigns".reset_buffer()<CR>',    'Reset buffer' },
			p = { ':lua require"gitsigns".preview_hunk()<CR>',    'Preview hunk' },
		},

		["1"] = { ':BufferLineGoToBuffer 1<CR>', "Go to buffer 1" },
		["2"] = { ':BufferLineGoToBuffer 2<CR>', "Go to buffer 2" },
		["3"] = { ':BufferLineGoToBuffer 3<CR>', "Go to buffer 3" },
		["4"] = { ':BufferLineGoToBuffer 4<CR>', "Go to buffer 4" },
		["5"] = { ':BufferLineGoToBuffer 5<CR>', "Go to buffer 5" },
		["6"] = { ':BufferLineGoToBuffer 6<CR>', "Go to buffer 6" },
		["7"] = { ':BufferLineGoToBuffer 7<CR>', "Go to buffer 7" },
		["8"] = { ':BufferLineGoToBuffer 8<CR>', "Go to buffer 8" },
		["9"] = { ':BufferLineGoToBuffer 9<CR>', "Go to buffer 9" },
	},

	g = {

		name = "Goto",

		d = { ':lua vim.lsp.buf.definition()<CR>',       'Definition'},
		t = { ':lua vim.lsp.buf.type_definition()<CR>',  'Type Definition'},
		D = { ':lua vim.lsp.buf.declaration()<CR>',      'Declaration'},
		r = { ':lua vim.lsp.buf.references()<CR>',       'References'},
		i = { ':lua vim.lsp.buf.implementation()<CR>',   'Implementation'},
		j = { ':lua vim.lsp.diagnostic.goto_next()<CR>', 'Next diagnostic' },
		k = { ':lua vim.lsp.diagnostic.goto_prev()<CR>', 'Previuous diagnostic' },

	},

	-- Cycle buffers
	['<C-n>'] = { ':bnext<CR>', 'Next buffer'},
	['<C-p>'] = { ':bprev<CR>', 'Previous buffer'},

	-- Remap the arrow keys to nothing
	['<left>']  = { '<nop>', 'Nothing'},
	['<right>'] = { '<nop>', 'Nothing'},
	['<up>']    = { '<nop>', 'Nothing'},
	['<down>']  = { '<nop>', 'Nothing'},

	-- Use Q for playing q macro
	Q = { '@q', 'Play q macro' },

})

-- Hide bufferline mappings
for i=1,9 do
	wk.register({
		[tostring(i)] = "which_key_ignore",
	}, { prefix = "<leader>"})
end

wk.register({

	-- Switch ; and :
	[';'] = { ':', 'Switch ; and :'},
	[':'] = { ';', 'Switch ; and :'},

}, {mode = 'n', silent=false})


-----------------
-- Visual mode --
-----------------

wk.register({

	-- Switch ; and :
	[';'] = { ':', 'Switch ; and :'},
	[':'] = { ';', 'Switch ; and :'},

	-- Indent lines and reselect visual group
	['<'] = { '<gv', 'Reselect on indenting lines'},
	['>'] = { '>gv', 'Reselect on indenting lines'},

	-- Move lines up and down
	['<C-k>'] = { ":m-2<CR>gv", 'Move line up'},
	['<C-j>'] = { ":m '>+<CR>gv", 'Move line down'},

	['<C-a>'] = { "g<C-a>", 'Visual increment numbers'},
	['<C-x>'] = { "g<C-x>", 'Visual decrement numbers'},
	['g<C-a>'] = { "<C-a>", 'Increment numbers'},
	['g<C-x>'] = { "<C-x>", 'Decrement numbers'},

	-- vnoremap <C-a> g<C-a>
	-- vnoremap <C-x> g<C-x>
	-- vnoremap g<C-a> <C-a>
	-- vnoremap g<C-x> <C-x>

}, {mode = 'v', silent=false})

-----------------
-- Insert mode --
-----------------
--
-- nvim_set_keymap('c', '',   'print(1)',   { noremap = true, expr = true })

wk.register({

	-- Completion
	['<C-Space>'] = { "compe#complete()",      'Trigger completion', expr=true },
	['<CR>']      = { "compe#confirm('<CR>')", 'Confirm completion', expr=true },
	-- ['<C-e>'] = { "<C-o>:call compe#close('C-e')<CR>", 'Close completion'},
}, {mode = 'i'})



-- TODO Set some keybinds conditional on server capabilities
-- if client.resolved_capabilities.document_formatting then
--   buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
-- elseif client.resolved_capabilities.document_range_formatting then
--   buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
-- end

