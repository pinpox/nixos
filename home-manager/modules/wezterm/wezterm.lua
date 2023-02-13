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

	-- experimental_shape_post_processing = true,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},

	audible_bell = "Disabled",

	set_environment_variables = {
		EDITOR = "nvim",
		VISUAL = "nvim"
	},

	-- Close pane/tab when shell exits (e.g. Ctrl-D)
	exit_behavior = "Close",

	-- Uses $SHELL by default. Only needed when using the appimage build
	-- default_prog = {"zsh", "-l"},

	-- Leader key, use with mods="LEADER"
	leader = { key="\\", mods="CTRL" },

	-- disable_default_key_bindings = true,
	debug_key_events = true,

	-- for tiling window managers
	adjust_window_size_when_changing_font_size = false,


	keys = {
		-- Panes
		{ key = "\\",   mods="LEADER|SHIFT",     action=wezterm.action{SplitHorizontal={domain="CurrentPaneDomain"}}},
		{ key = "\\",  mods="LEADER",     action=wezterm.action{SplitVertical={domain="CurrentPaneDomain"}}},
		{ key = "mapped:w",   mods="CTRL|SHIFT", action=wezterm.action{CloseCurrentPane={confirm=true}}},
		-- { key = "w",   mods="CTRL|SHIFT", action=wezterm.action{CloseCurrentTab={confirm=true}}
		{ key = "mapped:h",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Left"}},
		{ key = "mapped:l",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Right"}},
		{ key = "mapped:k",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Up"}},
		{ key = "mapped:j",   mods="CTRL|SHIFT", action=wezterm.action{ActivatePaneDirection="Down"}},
		-- Tabs
		{ key = "mapped:t",   mods="CTRL|SHIFT", action=wezterm.action{SpawnTab="CurrentPaneDomain"}},
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
		{family="Berkeley Mono" },
		"Noto Color Emoji",
	}),

	font_rules={
		-- {
		-- 	-- Italic
		-- 	italic=true,
		-- 	font = wezterm.font_with_fallback( {
		-- 		{family="Berkeley Mono", italic=true},
		-- 		"Inconsolata Nerd Font Mono",
		-- 		"Noto Color Emoji",
		-- 	}),
		-- },
		-- {
		-- 	-- Bold
		-- 	intensity="Bold", italic=false,
		-- 	font = wezterm.font_with_fallback( {
		-- 		{family="Berkeley Mono", weight="Bold"},
		-- 		"Inconsolata Nerd Font Mono",
		-- 		"Noto Color Emoji",
		-- 	}),
		-- },
		-- {
		-- 	-- Bold Italic
		-- 	intensity="Bold", italic=true,
		-- 	font = wezterm.font_with_fallback( {
		-- 		{family="Berkeley Mono", weight=700, stretch="Expanded"},
		-- 		"Noto Color Emoji",
		-- 	}),
		-- },
	},

	-- -- Font options
	-- harfbuzz_features = {
	--		"dlig", -- Ligatures
	--		"ss01", -- Single-story a
	--		"ss02", -- Single-story g
	--		"ss03", -- Simplified f
	--		"ss04", -- Simplified i
	--		"ss05", -- Simplified l
	--		"ss06", -- Simplified
	--		-- "ss07", -- Simplified italic diagonals (kwxyz)
	--		-- "ss08", -- No-serif L and Z
	--		-- "ss09", -- Simplified 6 and 9
	--		-- "ss10", -- Dotted 0
	--		"ss11", -- Simplified 1
	--		"ss12", -- Simplified @
	-- },

	-- Font rendering
	freetype_render_target = "Light",

	-- Cursor style
	default_cursor_style = "SteadyBar",

	-- Hide tab bar when there is only a single tab
	hide_tab_bar_if_only_one_tab = true,

	-- Transparency
	window_background_opacity = 0.9,

	skip_close_confirmation_for_processes_named = {
		'bash',
		'sh',
		'zsh',
		'fish',
		'tmux',
		'zellij',
	},

	colors = require("colors"),

}
