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
wk.add({

	-- Cycle buffers
    { "<C-n>", ":bnext<CR>", desc = "Next buffer" },
    { "<C-p>", ":bprev<CR>", desc = "Previous buffer" },

    { "<leader>1", ":BufferLineGoToBuffer 1<CR>", desc = "Go to buffer 1" },
    { "<leader>2", ":BufferLineGoToBuffer 2<CR>", desc = "Go to buffer 2" },
    { "<leader>3", ":BufferLineGoToBuffer 3<CR>", desc = "Go to buffer 3" },
    { "<leader>4", ":BufferLineGoToBuffer 4<CR>", desc = "Go to buffer 4" },
    { "<leader>5", ":BufferLineGoToBuffer 5<CR>", desc = "Go to buffer 5" },
    { "<leader>6", ":BufferLineGoToBuffer 6<CR>", desc = "Go to buffer 6" },
    { "<leader>7", ":BufferLineGoToBuffer 7<CR>", desc = "Go to buffer 7" },
    { "<leader>8", ":BufferLineGoToBuffer 8<CR>", desc = "Go to buffer 8" },
    { "<leader>9", ":BufferLineGoToBuffer 9<CR>", desc = "Go to buffer 9" },


    { "<leader>c", group = "Code (LSP)" },
    { "<leader>cS", ":FzfLua lsp_document_symbols<CR>", desc = "Symbols" },
    { "<leader>ca", ":FzfLua lsp_code_actions<CR>", desc = "Code actions" },
    { "<leader>cd", ":lua vim.diagnostic.open_float() <CR>", desc = "Line diagnostics" },
    { "<leader>cf", ":lua vim.lsp.buf.format()<CR>", desc = "Autoformat" },
    { "<leader>ci", ":lua vim.lsp.buf.hover()<CR>", desc = "Hover information" },
    { "<leader>cs", ":lua vim.lsp.buf.signature_help()<CR>", desc = "Signature" },

	-- FZF
    { "<leader>F", ":FzfLua git_files<CR>", desc = "Git files" },
    { "<leader>f", ":FzfLua files<CR>", desc = "Files" },
    { "<leader>b", ":FzfLua buffers<CR>", desc = "Buffers" },
    { "<leader>q", ":FzfLua quickfix<CR>", desc = "Quickfix" },
    { "<leader>G", ":FzfLua live_grep<CR>", desc = "Live Grep" },
    { "<leader>r", ":lua vim.lsp.buf.rename()<CR>", desc = "Rename" },

    { "<leader>g", group = "Git" },
    { "<leader>gR", ':lua require"gitsigns".reset_buffer()<CR>', desc = "Reset buffer" },
    { "<leader>gb", ':lua require"gitsigns".blame_line()<CR>', desc = "Git Blame line" },
    { "<leader>gp", ':lua require"gitsigns".preview_hunk()<CR>', desc = "Preview hunk" },
    { "<leader>gr", ':lua require"gitsigns".reset_hunk()<CR>', desc = "Reset hunk" },
    { "<leader>gs", ':lua require"gitsigns".stage_hunk()<CR>', desc = "Stage hunk" },
    { "<leader>gu", ':lua require"gitsigns".undo_stage_hunk()<CR>', desc = "Undo stage hunk" },


	-- Remap the arrow keys to nothing
    { "<left>", "<nop>", desc = "Nothing" },
    { "<right>", "<nop>", desc = "Nothing" },
    { "<up>", "<nop>", desc = "Nothing" },
    { "<down>", "<nop>", desc = "Nothing" },

	-- Use Q for playing q macro
    { "Q", "@q", desc = "Play q macro" },

    { "g", group = "Goto" },
    { "gD", ":lua vim.lsp.buf.declaration()<CR>", desc = "Declaration" },
    { "gd", ":lua vim.lsp.buf.definition()<CR>", desc = "Definition" },
    { "gi", ":lua vim.lsp.buf.implementation()<CR>", desc = "Implementation" },
    { "gj", ":lua vim.lsp.diagnostic.goto_next()<CR>", desc = "Next diagnostic" },
    { "gk", ":lua vim.lsp.diagnostic.goto_prev()<CR>", desc = "Previuous diagnostic" },
    { "gr", ":FzfLua lsp_references<CR>", desc = "References" },
    { "gt", ":lua vim.lsp.buf.type_definition()<CR>", desc = "Type Definition" },


	-- Switch ; and :
    { ":", ";", desc = "Switch ; and :", silent = false },
    { ";", ":", desc = "Switch ; and :", silent = false },

  })


-- Hide bufferline mappings
-- for i=1,9 do
-- 	wk.register({
-- 		[tostring(i)] = "which_key_ignore",
-- 	}, { prefix = "<leader>"})
-- end




-----------------
-- Visual mode --
-----------------
wk.add({
  {
    mode = { "v" },

	-- Switch ; and :
    { ":", ";", desc = "Switch ; and :", silent = false },
    { ";", ":", desc = "Switch ; and :", silent = false },

	-- Move lines up and down
    { "<C-j>", ":m '>+<CR>gv", desc = "Move line down", silent = false },
    { "<C-k>", ":m-2<CR>gv", desc = "Move line up", silent = false },

    { "<C-a>", "g<C-a>", desc = "Visual increment numbers", silent = false },
    { "<C-x>", "g<C-x>", desc = "Visual decrement numbers", silent = false },
    { "g<C-a>", "<C-a>", desc = "Increment numbers", silent = false },
    { "g<C-x>", "<C-x>", desc = "Decrement numbers", silent = false },

	-- Indent lines and reselect visual group
    { "<", "<gv", desc = "Reselect on indenting lines", silent = false },
    { ">", ">gv", desc = "Reselect on indenting lines", silent = false },
  },
})

-----------------
-- Insert mode --
-----------------
--
-- nvim_set_keymap('c', '',   'print(1)',   { noremap = true, expr = true })

-- wk.register({
	-- Completion
	-- ['<C-Space>'] = { "compe#complete()",      'Trigger completion', expr=true },
	-- ['<CR>']      = { "compe#confirm('<CR>')", 'Confirm completion', expr=true },
	-- ['<C-e>'] = { "<C-o>:call compe#close('C-e')<CR>", 'Close completion'},
-- }, {mode = 'i'})



-- TODO Set some keybinds conditional on server capabilities
-- if client.resolved_capabilities.document_formatting then
--   buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
-- elseif client.resolved_capabilities.document_range_formatting then
--   buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
-- end

