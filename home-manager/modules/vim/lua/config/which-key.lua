local wk = require("which-key")
wk.setup {}

-----------------
-- Normal mode --
-----------------

wk.register({

    -- Leader key
    ["<leader>"] = {

	F = { ':GFiles<CR>',  'Git files' },
	f = { ':Files<CR>',   'Files' },
	b = { ':Buffers<CR>', 'Buffers' },

	h = {
	    name = "Help",
	    h = { '<cmd>lua vim.lsp.buf.hover()<CR>', 'Hover information' },
	    s = { '<cmd>lua vim.lsp.buf.signature_help()<CR>', 'Signature' },
	},

    },

    g = {

	name = "Goto",

	d = { ':lua vim.lsp.buf.definition()<CR>',     'Definition'},
	D = { ':lua vim.lsp.buf.declaration()<CR>',    'Declaration'},
	r = { ':lua vim.lsp.buf.references()<CR>',     'References'},
	i = { ':lua vim.lsp.buf.implementation()<CR>', 'Implementation'},
	j = { ':lua vim.lsp.diagnostic.goto_next()<CR>', 'Next diagnostic' },
	k = { ':lua vim.lsp.diagnostic.goto_prev()<CR>', 'Previuous diagnostic' },

    },

    -- Cycle buffers
    ['<C-n>'] = { ':bnext<CR>', 'Next buffer'},
    ['<C-p>'] = { ':bprev<CR>', 'Previous buffer'},

    -- Switch ; and :
    [';'] = { ':', 'Switch ; and :'},
    [':'] = { ';', 'Switch : and ;'},

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

}, {mode = 'v'})

-----------------
-- Insert mode --
-----------------

wk.register({

    -- Completion
    ['<C-Space>'] = { '<C-o>:call compe#complete()<CR>', 'Trigger completion'},
    ['<C-e>'] = { "<C-o>:call compe#close('C-e')<CR>", 'Close completion'},

}, {mode = 'i'})


