
-- Eviline config for lualine

--   +-------------------------------------------------+
--   | A | B | C                             X | Y | Z |
--   +-------------------------------------------------+

-- Author: shadmansaleh
-- Credit: glepnir

local lualine = require'lualine'

-- -- Color table for highlights
local colors = {
	bg       = '#202328',
	fg       = '#bbc2cf',
	yellow   = '#ECBE7B',
	cyan     = '#008080',
	darkblue = '#081633',
	green    = '#98be65',
	orange   = '#FF8800',
	violet   = '#a9a1e1',
	magenta  = '#c678dd',
	blue     = '#51afef';
	red      = '#ec5f67';
}

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
	check_git_workspace = function()
		local filepath = vim.fn.expand('%:p:h')
		local gitdir = vim.fn.finddir('.git', filepath .. ';')
		return gitdir and #gitdir > 0 and #gitdir < #filepath
	end
}

-- -- Config
local config = {
	options = {
		-- Disable sections and component separators
		component_separators = "",
		section_separators = "",
		theme = 'auto',
	},
	sections = {
		lualine_a = {  },
		lualine_b = { {'branch', icon = ''} },
		-- These will be filled later
		lualine_c = {
			{
				function() return '▊' end,
				color = {fg = colors.blue}, -- Sets highlighting of component
				left_padding = 0 -- We don't need space before this
			},
			{
				-- mode component
				function()
					-- auto change color according the vim mode
					local mode_color = {
						n      = colors.red,
						i      = colors.green,
						v      = colors.blue,
						[''] = colors.blue,
						V      = colors.blue,
						c      = colors.magenta,
						no     = colors.red,
						s      = colors.orange,
						S      = colors.orange,
						[''] = colors.orange,
						ic     = colors.yellow,
						R      = colors.violet,
						Rv     = colors.violet,
						cv     = colors.red,
						ce     = colors.red,
						r      = colors.cyan,
						rm     = colors.cyan,
						['r?'] = colors.cyan,
						['!']  = colors.red,
						t      = colors.red
					}
					vim.api.nvim_command('hi! LualineMode guifg='..mode_color[vim.fn.mode()] .. " guibg="..colors.bg)
					-- vim.api.nvim_command('hi! LualineMode guifg='..mode_color[vim.fn.mode()])
					return ' '
				end,
				color = "LualineMode",
				left_padding = 0,
			},
			{
				-- filesize component
				function()
					local function format_file_size(file)
						local size = vim.fn.getfsize(file)
						if size <= 0 then return '' end
						local sufixes = {'b', 'k', 'm', 'g'}
						local i = 1
						while size > 1024 do
							size = size / 1024
							i = i + 1
						end
						return string.format('%.1f%s', size, sufixes[i])
					end
					local file = vim.fn.expand('%:p')
					if string.len(file) == 0 then return '' end
					return format_file_size(file)
				end,
				condition = conditions.buffer_not_empty,
			},
			{
				'filename',
				condition = conditions.buffer_not_empty,
				color = {fg = colors.magenta, gui = 'italic'},
			},
			{'location'},
			{
				'progress',
				color = {fg = colors.fg, gui = 'bold'},
			},
			{
				'diagnostics',
				sources = {'nvim_lsp'},
				symbols = {error = ' ', warn = ' ', info= ' '},
				color_error = colors.red,
				color_warn = colors.yellow,
				color_info = colors.cyan,
			},
			-- Insert mid section. You can make any number of sections in neovim :)
			-- for lualine it's any number gretter then 2
			{function() return '%=' end},
			{
				-- Lsp server name .
				function ()
					local msg = 'No Active Lsp'
					local buf_ft = vim.api.nvim_buf_get_option(0,'filetype')
					local clients = vim.lsp.get_active_clients()
					if next(clients) == nil then return msg end
					for _, client in ipairs(clients) do
						local filetypes = client.config.filetypes
						if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
							return client.name
						end
					end
					return msg
				end,
				icon = ' LSP:',
				color = {fg = colors.cyan, gui = 'bold'}
			},
		},
		lualine_x = {

			-- Add components to right sections
			{
				'o:encoding', -- option component same as &encoding in viml
				upper = true, -- I'm not sure why it's uper case either ;)
				condition = conditions.hide_in_width,
				color = {fg = colors.green, gui = 'bold'}
			},

			{
				'fileformat',
				upper = true,
				icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
				color = {fg = colors.green, gui='bold'},
			},

			{
				'branch',
				icon = '',
				condition = conditions.check_git_workspace,
				color = {fg = colors.violet, gui = 'italic'},
			},

			{
				'diff',
				-- Is it me or the symbol for modified us really weird
				symbols = {added= ' ', modified= ' ', removed= ' '},
				color_added = colors.green,
				color_modified = colors.orange,
				color_removed = colors.red,
				condition = conditions.hide_in_width
			},

			{
				function() return '▊' end,
				color = {fg = colors.blue},
				right_padding = 0,
			},
		},
	},
	inactive_sections = {}
}

-- Inserts a component in lualine_c ot left section
local function ins_left(component)
	table.insert(config.sections.lualine_c, component)
end



-- Now don't forget to initialize lualine
lualine.setup(config)
