require("zk").setup({
	-- can be "telescope", "fzf", "fzf_lua", "minipick", or "select" (`vim.ui.select`)
	-- it's recommended to use "telescope", "fzf", "fzf_lua", or "minipick"
	picker = "fzf_lua",

	log = true,
	default_keymaps = true,
	default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "/home/pinpox/Notes",
	link_format = "wiki", -- or "wiki"

	lsp = {
		-- `config` is passed to `vim.lsp.start_client(config)`
		config = {
			cmd = { "zk", "lsp" },
			name = "zk",
			-- on_attach = ...
			-- etc, see `:h vim.lsp.start_client()`
		},

		-- automatically attach buffers in a zk notebook that match the given filetypes
		auto_attach = {
			enabled = true,
			filetypes = { "markdown" },
		},
	},
})
