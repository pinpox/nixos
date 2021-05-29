local wezterm = require 'wezterm';

-- Show date and battery level at the right of the tab bar
-- TODO Add tab decorations and hostname
-- https://wezfurlong.org/wezterm/config/lua/window/set_right_status.html
wezterm.on("update-right-status", function(window, pane)
	-- "Wed Mar 3 08:14"
	local date = wezterm.strftime("📆  %a %b %-d %H:%M ");

	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = "⚡" .. string.format("%.0f%%", b.state_of_charge * 100)
	end

	window:set_right_status(wezterm.format({
		{Text=bat .. "   "..date},
	}));
end)


return {


	set_environment_variables = {
		EDITOR = "nvim"
	},

	-- Uses $SHELL by default. Only needed when using the appimage build
	-- default_prog = {"zsh", "-l"},

	-- Leader key, use with mods="LEADER"
	leader = { key="a", mods="CTRL" },

	keys = {
		-- Panes
		{ key = "|",  mods="LEADER",     action=wezterm.action{SplitHorizontal={domain="CurrentPaneDomain"}}},
		{ key = "\\",   mods="LEADER",     action=wezterm.action{SplitVertical={domain="CurrentPaneDomain"}}},
		{ key = "w",   mods="CTRL|SHIFT", action=wezterm.action{CloseCurrentPane={confirm=true}}},
		{ key = "h",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Left"}},
		{ key = "l",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Right"}},
		{ key = "k",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Up"}},
		{ key = "j",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Down"}},
		-- Tabs
		{ key = "Tab", mods="CTRL",       action=wezterm.action{ActivateTabRelative=-1}},
		{ key = "Tab", mods="CTRL|SHIFT", action=wezterm.action{ActivateTabRelative=1}},
		{ key = "1",   mods="CTRL",       action=wezterm.action{ActivateTab=(1-1)}},
		{ key = "2",   mods="CTRL",       action=wezterm.action{ActivateTab=(2-1)}},
		{ key = "3",   mods="CTRL",       action=wezterm.action{ActivateTab=(3-1)}},
		{ key = "4",   mods="CTRL",       action=wezterm.action{ActivateTab=(4-1)}},
		{ key = "5",   mods="CTRL",       action=wezterm.action{ActivateTab=(5-1)}},
		{ key = "6",   mods="CTRL",       action=wezterm.action{ActivateTab=(6-1)}},
		{ key = "7",   mods="CTRL",       action=wezterm.action{ActivateTab=(7-1)}},
		{ key = "8",   mods="CTRL",       action=wezterm.action{ActivateTab=(8-1)}},
		{ key = "9",   mods="CTRL",       action=wezterm.action{ActivateTab=(9-1)}},
	},


	-- Default font
	font = wezterm.font_with_fallback( {
		{family="Recursive Mono Linear Static", weight="Medium"},
		"Inconsolata Nerd Font Mono",
		"Noto Color Emoji",
	}),

	font_rules={
		{
			-- Italic
			italic=true,
			font = wezterm.font_with_fallback( {
				{family="Recursive Mono Casual Static", italic=true},
				"Inconsolata Nerd Font Mono",
				"Noto Color Emoji",
			}),
		},
		{
			-- Bold
			intensity="Bold", italic=false,
			font = wezterm.font_with_fallback( {
				{family="Recursive Mono Linear Static", weight="Bold"},
				"Inconsolata Nerd Font Mono",
				"Noto Color Emoji",
			}),
		},
		{
			-- Bold Italic
			intensity="Bold", italic=true,
			font = wezterm.font_with_fallback( {
				{family="Recursive Mono Casual Static", weight="Bold", italic=true},
				"Inconsolata Nerd Font Mono",
				"Noto Color Emoji",
			}),
		},
	},

	-- Font options
	harfbuzz_features = {
		"dlig", -- Ligatures
		"ss01", -- Single-story a
		"ss02", -- Single-story g
		"ss03", -- Simplified f
		"ss04", -- Simplified i
		"ss05", -- Simplified l
		"ss06", -- Simplified
		-- "ss07", -- Simplified italic diagonals (kwxyz)
		-- "ss08", -- No-serif L and Z
		-- "ss09", -- Simplified 6 and 9
		-- "ss10", -- Dotted 0
		"ss11", -- Simplified 1
		"ss12", -- Simplified @
	},

	-- Font rendering
	freetype_render_target = "Light",


	-- Cursor style
	default_cursor_style = "SteadyBar",

	-- Hide tab bar when there is only a single tab
	hide_tab_bar_if_only_one_tab = true,

	-- Transparency
	window_background_opacity = 0.9,

	colors = {

		foreground = "#E5E9F0",
		background = "#2E3440",

		-- Overrides the cell background color when the current cell is occupied by the
		-- cursor and the cursor style is set to Block
		cursor_bg = "#E5E9F0",

		-- Overrides the text color when the current cell is occupied by the cursor
		cursor_fg = "#F07178",

		-- Specifies the border color of the cursor when the cursor style is set to Block,
		-- of the color of the vertical or horizontal bar when the cursor style is set to
		-- Bar or Underline.
		cursor_border = "#82AAFF",

		-- The color of the split lines between panes
		split = "#82AAFF",

		-- Default colors
		ansi    = {"#2E3440", "#F07178", "#C3E88D", "#FFCB6B", "#82AAFF", "#C792EA", "#89DDFF", "#E5E9F0"},
		brights = {"#4C566A", "#F07178", "#C3E88D", "#FFCB6B", "#82AAFF", "#C792EA", "#89DDFF", "#8FBCBB"},

		tab_bar = {

			-- The color of the strip that goes along the top of the window
			background = "#3B4252",

			-- The active tab is the one that has focus in the window
			active_tab         = { bg_color = "#82AAFF", fg_color = "#2E3440" },
			inactive_tab       = { bg_color = "#2E3440", fg_color = "#808080" },
			inactive_tab_hover = { bg_color = "#3b3052", fg_color = "#909090" },
		},
	},

}


