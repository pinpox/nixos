-- Setup nvim-cmp.

local has_words_before = function()
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local luasnip = require("luasnip")
local cmp = require("cmp")
-- Lazy load snippets for each lang
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
     formatting = {
                format = require("nvim-highlight-colors").format
        },
		snippet = {
				-- REQUIRED - you must specify a snippet engine
				expand = function(args)
					require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
				end,
		},
		mapping = {
				['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
				['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
				['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
				['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
				['<C-e>'] = cmp.mapping({
						i = cmp.mapping.abort(),
						c = cmp.mapping.close(),
				}),
				['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

				["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
								cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
								luasnip.expand_or_jump()
						elseif has_words_before() then
								cmp.complete()
						else
								fallback()
						end
				end, { "i", "s" }),

				["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
								cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
								luasnip.jump(-1)
						else
								fallback()
						end
				end, { "i", "s" }),
		},
		sources = cmp.config.sources({
				{ name = 'path' }, -- for cmp-path in buffer
				{ name = 'nvim_lsp' },
				{ name = 'luasnip' }, -- For luasnip users.
				{ name = 'calc' },
				{ name = 'nvim_lua' },
				-- Setting spell (and spelllang) is mandatory to use spellsuggest.
				-- vim.opt.spell = true
				-- vim.opt.spelllang = { 'en_us' }
				{ name = 'spell' },
				{ name = 'emoji' },
				-- { name = 'cmdline' }, -- if not using wilder
		}, {
				{ name = 'buffer' },
		})
})
-- if not using wilder
-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline('/', {
--		sources = {
--				{ name = 'buffer' }
--		}
-- })
-- if not using wilder
-- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline(':', {
--		sources = cmp.config.sources({
--				{ name = 'path' }
--		}, {
--				{ name = 'cmdline' }
--		})
-- })

-- -- Setup lspconfig. The nvim-cmp almost supports LSP's capabilities so You
-- should advertise it to LSP servers.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- # cmp_nvim_lsp.update_capabilities is deprecated, use cmp_nvim_lsp.default_capabilities i

-- -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
-- require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
--   capabilities = capabilities
-- }
