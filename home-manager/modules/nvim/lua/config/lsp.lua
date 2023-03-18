require'lspconfig'.pyright.setup{}
require'lspconfig'.gopls.setup{}
require'lspconfig'.terraformls.setup{}
require'lspconfig'.bashls.setup{}
require'lspconfig'.yamlls.setup{}
require'lspconfig'.rust_analyzer.setup{}
require'lspconfig'.ltex.setup{}
-- require'lspconfig'.rls.setup{}

require'lspconfig'.nil_ls.setup{}

require'lspconfig'.lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global

        globals = {
		    -- AwesomeWM
		    "awesome", 
		    "client",
		    "screen",
		    "root",
		    -- Vim
		    'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),


		-- library = {
		--     [vim.fn.expand('$VIMRUNTIME/lua')] = true,
		--     [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,

		--     -- TODO find a way to add the nix store path dynamically.
		--     -- This will break on update!
		--     [vim.fn.expand('/nix/store/3xx4k57zz8l3hvzqd4v3v0ffgspp3pan-awesome-4.3/share/awesome/lib')] = true,
		-- },
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}


-- require'lspconfig'.sumneko_lua.setup {
--     cmd = { 'lua-language-server' },
--     settings = {
-- 	Lua = {
-- 	    runtime = {
-- 		-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
-- 		version = 'LuaJIT',
-- 		-- Setup your lua path
-- 		path = vim.split(package.path, ';'),
-- 	    },
-- 	    diagnostics = {
-- 		-- Get the language server to recognize the vim and awesomwm
-- 		-- globals
-- 		globals = {
-- 		}
-- 	    },
-- 	    -- Do not send telemetry data containing a randomized but unique identifier
-- 	    workspace = {
-- 		-- adjust these two values if your performance is not optimal
-- 		maxPreload = 2000,
-- 		preloadFileSize = 1000
-- 	    }
-- 	}
--     },
--     -- on_attach = custom_attach,
-- }


require'lspconfig'.jsonls.setup {

    cmd = { "json-languageserver", "--stdio" },
    commands = {
	Format = {
	    function()
		vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
	    end
	}
    }
}

-- lspconfig updates while typing
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
vim.lsp.diagnostic.on_publish_diagnostics, { update_in_insert = true, })

local lspconfig = require('lspconfig')
local configs = require('lspconfig/configs')

configs.zk = {
  default_config = {
    cmd = {'zk', 'lsp', '--log', '/tmp/zk-lsp.log'},
    filetypes = {'markdown'},
    root_dir = function()
      return vim.loop.cwd()
    end,
    settings = {}
  };
}

lspconfig.zk.setup({ on_attach = function(client, buffer) 
  -- some custom on_attach function for doing keybindings and other things..
  -- see: https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
end })

-- TODO auto-format on save
-- autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 100)
-- autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 100)
-- autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 100
--

-- local saga = require 'lspsaga'
-- saga.init_lsp_saga()

-- DOC: To override defaults see: https://github.com/glepnir/lspsaga.nvim/
-- saga.init_lsp_saga {
--     use_saga_diagnostic_sign = true
--     error_sign = '',
--     warn_sign = '',
--     hint_sign = '',
--     infor_sign = '',
--     dianostic_header_icon = '   ',
--     code_action_icon = ' ',
--     code_action_prompt = {
--       enable = true,
--       sign = true,
--       sign_priority = 20,
--       virtual_text = true,
--     },
--     finder_definition_icon = '  ',
--     finder_reference_icon = '  ',
--     max_preview_lines = 10, -- preview lines of lsp_finder and definition preview
--     finder_action_keys = {
--       open = 'o', vsplit = 's',split = 'i',quit = 'q',scroll_down = '<C-f>', scroll_up = '<C-b>' -- quit can be a table
--     },
--     code_action_keys = {
--       quit = 'q',exec = '<CR>'
--     },
--     rename_action_keys = {
--       quit = '<C-c>',exec = '<CR>'  -- quit can be a table
--     },
--     definition_preview_icon = '  '
--     "single" "double" "round" "plus"
--     border_style = "single"
--     rename_prompt_prefix = '➤',
--     if you don't use nvim-lspconfig you must pass your server name and
--     the related filetypes into this table
--     like server_filetype_map = {metals = {'sbt', 'scala'}}
--     server_filetype_map = {}
-- }
