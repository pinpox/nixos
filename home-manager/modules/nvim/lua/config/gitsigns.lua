require('gitsigns').setup {
	signs = {

		-- copy from : https://en.wikipedia.org/wiki/Box-drawing_character
		add          = { text = '┃' },
		change       = { text = '┇' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '┇' },
	},

	numhl = false,
	linehl = false,
	watch_gitdir = {
		interval = 1000
	},
	current_line_blame = false,
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	-- use_internal_diff = true,  -- If luajit is present
	diff_opts = {
		internal = true,
	},
}
