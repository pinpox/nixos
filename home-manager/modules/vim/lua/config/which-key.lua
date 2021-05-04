local wk = require("which-key")
wk.setup {}

wk.register({
	f = {
		name = "+file",
		f = { ":Files<CR>",  "Find files" },
		F = { ":GFiles<CR>", "Find git files" },
	},

}, { prefix = "<leader>"})


vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<CR>', { noremap = true, silent = true })

-- Switch ; and :
vim.api.nvim_set_keymap('n', ';', ':', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ':', ';', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', ';', ':', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', ':', ';', { noremap = true, silent = true })



-- Remap the arrow keys to nothing
vim.api.nvim_set_keymap('n', '<left>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<right>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<up>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<down>', '<nop>', { noremap = true, silent = true })

-- Cycle buffers
vim.api.nvim_set_keymap('n', '<C-n>', ':bnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-p>', ':bprev<CR>', { noremap = true, silent = true })

-- indent lines and reselect visual group
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, silent = true })


-- move lines up and down
-- vnoremap <C-k> :m-2<CR>gv
-- vnoremap <C-j> :m '>+<CR>gv

-- Overwrite with yanked text in visual mode
-- xnoremap p "_dP

-- Use Q for playing q macro
vim.api.nvim_set_keymap('n', 'Q', '@q', { noremap = true, silent = true })

-- Spell checking
vim.api.nvim_set_keymap('n', '<F5>', '[s', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F6>', '1z=', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F7>', 'z=', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F8>', ':spellr<CR>', { noremap = true, silent = true })






-- TODO mappings to lua
-- " LSP config (the mappings used in the default file don't quite work right)
vim.api.nvim_set_keymap('n', 'gd',    '<cmd>lua vim.lsp.buf.definition()<CR>',       { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gD',    '<cmd>lua vim.lsp.buf.declaration()<CR>',      { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gr',    '<cmd>lua vim.lsp.buf.references()<CR>',       { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gi',    '<cmd>lua vim.lsp.buf.implementation()<CR>',   { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'K',     '<cmd>lua vim.lsp.buf.hover()<CR>',            { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',   { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-n>', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-p>', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', { noremap = true, silent = true})

-- Start interactive EasyAlign in visual mode (e.g. vipga)
-- xmap ga <Plug>(EasyAlign)

-- Start interactive EasyAlign for a motion/text object (e.g. gaip)
-- nmap ga <Plug>(EasyAlign)

-- Leader keys
-- let g:mapleader      = "\<Space>"
-- let g:maplocalleader = ','
-- nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
-- nnoremap <silent> <localleader> :<c-u>WhichKey ','<CR>

-- Completion
vim.api.nvim_set_keymap('i', '<C-Space>', 'compe#complete()', { noremap = true, silent = true})
-- inoremap <silent><expr> <C-Space> compe#complete()
-- inoremap <silent><expr> <CR>      compe#confirm('<CR>')
-- inoremap <silent><expr> <C-e>     compe#close('<C-e>')
-- inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
-- inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
