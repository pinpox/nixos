-- Switcch ; and :
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

-- Leader commands
-- Set mapleader to space
vim.g.mapleader = " "

-- open a file using fzf
vim.api.nvim_set_keymap('n', '<leader>f', ':Files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>F', ':GFiles<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>t', ':Vista finder<CR>', { noremap = true, silent = true })


