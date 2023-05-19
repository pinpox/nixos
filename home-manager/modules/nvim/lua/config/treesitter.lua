require'nvim-treesitter'.setup {
	-- ensure_installed = { },

	-- Install ascynchroniously
	sync_install = false,

	auto_install = true,

	highlight = {
		enable = true,

		-- Disable specific languages
		-- disable = { "c", "rust" },

		additional_vim_regex_highlighting = false,
	},
}
