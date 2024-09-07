vim.g.indentLine_char = '│'
vim.g.buftabline_indicators = 1
--vim.g.indent_blankline_use_treesitter_scope = true

vim.opt.list = true
vim.opt.listchars:append "space:⋅"
-- vim.opt.listchars:append "eol:↴"

require("ibl").setup {
    -- space_char_blankline = " ",
    -- show_current_context = true,
    -- show_current_context_start = false,
}

-- require'colorizer'.setup()
-- Ensure termguicolors is enabled if not already
vim.opt.termguicolors = true
require('nvim-highlight-colors').setup({})

-- TODO convert to lua
vim.cmd 'let $NVIM_TUI_ENABLE_TRUE_COLOR=1'
vim.cmd "set listchars=tab:\\│\\ ,trail:·,nbsp:\\ " -- Display trailing whitespace
-- vim.cmd 'set termguicolors'
-- vim.cmd 'let base16colorspace=256'
vim.cmd 'set noshowmode'                               -- Don't show current mode below the bar
-- vim.cmd 'match CursorLine /\\%>100c/'               -- Color lines exceeding length of 100
vim.cmd 'set signcolumn=yes'
