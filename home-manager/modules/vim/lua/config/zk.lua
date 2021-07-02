require("zk").setup({
  debug = false,
  log = true,
  default_keymaps = true,
  default_notebook_path = vim.env.ZK_NOTEBOOK_DIR or "/home/pinpox/Notes",
  fuzzy_finder = "fzf", -- or "telescope"
  link_format = "wiki" -- or "wiki"
})
