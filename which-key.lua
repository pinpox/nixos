local wk = require('whichkey_setup')

local keymap = {

	-- w = {':w!<CR>', 'save file'} -- set a single command and text
	-- j = 'split args' -- only set a text for an already configured keymap
	-- ['<CR>'] = {'@q', 'macro q'}, -- setting a special key
	g = {
		name = '+GOTO',
		d = {'<Plug>(coc-definition)'      , 'Definition'},
		y = {'<Plug>(coc-type-difinition)' , 'Type definiton'},
		i = {'<Plug>(coc-implementation)'  , 'Implementation'},
		r = {'<Plug>(coc-references)'      , 'References'},
	},

	l = {
		name = '+LSP',
		f = {'<Plug>(coc-format-selected)' , 'Autoformat'},
		R = {'<Plug>(coc-references)'      , 'References'},
		r = {'<Plug>(coc-rename)'          , 'Rename'},
		a = {'<Plug>(coc-codeaction)'      , 'Code action'},
		F = {'<Plug>(coc-fix-current)'     , 'Fix automatically'},
		o = {':CocList outline'            , 'Code outline'},
		s = {':CocList -I symbols'         , 'Symbols'},
		d = {':CocList dignostics'         , 'Diagnostics'},
		e = {':CocList extensions'         , 'Extensions'},
		c = {':CocList commands'           , 'Commands'},
		b = {'<Plug>(coc-bookmark-toggle)' , 'Toggle bookmark'},
	},

	w = {
		name = '+WINDOWS' ,
		w = {'<C-W>w'     , 'other-window'},
		d = {'<C-W>c'     , 'delete-window'},
		-- | = {'<C-W>v'     , 'split-window-right'},
		h = {'<C-W>h'     , 'window-left'},
		j = {'<C-W>j'     , 'window-below'},
		l = {'<C-W>l'     , 'window-right'},
		k = {'<C-W>k'     , 'window-up'},
		H = {'<C-W>5<'    , 'expand-window-left'},
		J = {':resize +5' , 'expand-window-below'},
		L = {'<C-W>5>'    , 'expand-window-right'},
		K = {':resize -5' , 'expand-window-up'},
		-- = = {'<C-W>='     , 'balance-window'},
		s = {'<C-W>s'     , 'split-window-below'},
		v = {'<C-W>v'     , 'split-window-below'},
		-- ? = {'Windows'    , 'fzf-window'},
	},

	o = {
		name = '+open',
		q = {'open-quickfix'},
		l = {'open-locationlist'},
	},

	f = { -- set a nested structure
		name = '+find',
		b = {'<Cmd>Telescope buffers<CR>', 'buffers'},
		h = {'<Cmd>Telescope help_tags<CR>', 'help tags'},
		c = {
			name = '+commands',
			c = {'<Cmd>Telescope commands<CR>', 'commands'},
			h = {'<Cmd>Telescope command_history<CR>', 'history'},
		},
		q = {'<Cmd>Telescope quickfix<CR>', 'quickfix'},
		g = {
			name = '+git',
			g = {'<Cmd>Telescope git_commits<CR>', 'commits'},
			c = {'<Cmd>Telescope git_bcommits<CR>', 'bcommits'},
			b = {'<Cmd>Telescope git_branches<CR>', 'branches'},
			s = {'<Cmd>Telescope git_status<CR>', 'status'},
		},
	},
}

wk.register_keymap('leader', keymap)
