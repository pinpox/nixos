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
	watch_index = {
		interval = 1000
	},
	current_line_blame = false,
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	use_internal_diff = true,  -- If luajit is present
}
