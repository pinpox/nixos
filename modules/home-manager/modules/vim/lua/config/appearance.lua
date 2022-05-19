vim.g.indentLine_char = '│'
vim.g.buftabline_indicators = 1

require'colorizer'.setup()

-- TODO convert to lua
vim.cmd 'let $NVIM_TUI_ENABLE_TRUE_COLOR=1'
vim.cmd "set listchars=tab:\\│\\ ,trail:·,nbsp:\\ " -- Display trailing whitespace
vim.cmd "set list"
-- vim.cmd 'set termguicolors'
-- vim.cmd 'let base16colorspace=256'
-- vim.cmd 'colorscheme ansible-theme'
-- vim.cmd 'highlight Comment cterm=italic gui=italic' -- Italic comments
vim.cmd 'set noshowmode'                            -- Don't show current mode below the bar
vim.cmd 'match CursorLine /\\%>100c/'               -- Color lines exceeding length of 100
vim.cmd 'set signcolumn=yes'

-- require('colorbuddy').colorscheme('pinpox-colors')

-- todo-comments.nvim
-- require("todo-comments").setup {}
