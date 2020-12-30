local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Mouse bindings
root.buttons(gears.table.join(
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewnext),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(

-- Focus

-- Focus right
awful.key({ modkey, }, "h", function ()
	awful.client.focus.global_bydirection("left")
end, {description = "Focus right", group = "Focus"}),

-- Focus left
awful.key({ modkey, }, "l", function ()
	awful.client.focus.global_bydirection("right")
end, {description = "Focus left", group = "Focus"}),

-- Focus below
awful.key({ modkey, }, "j", function ()
	awful.client.focus.global_bydirection("down")
end, {description = "Focus below", group = "Focus"}),

-- Focus above
awful.key({ modkey, }, "k", function ()
	awful.client.focus.global_bydirection("up")
end, {description = "Focus above", group = "Focus"}),

-- Focus urgent
awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
{description = "jump to urgent client", group = "Focus"}),

-- Cycle with mod+tab
awful.key({ modkey, }, "Tab", function ()
	awful.client.focus.byidx( 1)
end, {description = "Focus next", group = "Focus"}),

awful.key({ modkey, "Shift"}, "Tab", function ()
	awful.client.focus.byidx(-1)
end, {description = "Focus previous", group = "Focus"}
),

-- Focus previous window (back-n-forth)
awful.key({ modkey, }, "`", function ()
	awful.client.focus.history.previous()
	if client.focus then
		client.focus:raise()
	end
end, {description = "go back", group = "Focus"}),

-- Switch layout tiling/tab
awful.key({ modkey, }, "space", function ()
	awful.layout.inc( 1)
end, {description = "Next layout", group = "Layout"}),

-- Master window
awful.key({ modkey, }, "]", function ()
	awful.tag.incmwfact( 0.05)
end, {description = "Grow master", group = "Layout"}),

awful.key({ modkey, }, "[", function ()
	awful.tag.incmwfact(-0.05)
end, {description = "Shrink master", group = "Layout"}),

-- Stack windows
awful.key({ modkey, }, "=", function ()
	awful.tag.incncol( 1, nil, true)
end, {description = "Add columns", group = "Layout"}),

awful.key({ modkey, }, "-", function ()
	awful.tag.incncol(-1, nil, true)
end, {description = "Substract columns", group = "Layout"}),

-- Standard programs
awful.key({ modkey, }, "Return", function ()
	awful.spawn(terminal)
end, {description = "Open terminal", group = "Other"}),

-- Other
awful.key({ modkey, }, "/", hotkeys_popup.show_help,
{description="Show help", group="Other"}),

awful.key({ modkey, "Control" }, "r", awesome.restart,
{description = "Reload awesome", group = "Other"}),

awful.key({ modkey, "Shift"   }, "e", awesome.quit,
{description = "Quit awesome", group = "Other"}),

awful.key({}, "Print", function ()
	awful.spawn.with_shell("import png:- | xclip -selection clipboard -t image/png")
end, {description = "Screenshot to Clipboard", group = "Other"}),

-- Prompt
awful.key({ modkey }, "r", function ()
	awful.screen.focused().mypromptbox:run()
end, {description = "Run command", group = "Other"}),

awful.key({ modkey }, "p", function()
	menubar.show()
end, {description = "Run application", group = "Other"})
)

clientkeys = gears.table.join(

-- Fullscreen and floating toggle
awful.key({ modkey, }, "f", function (c)
	c.fullscreen = not c.fullscreen
	c:raise()
end, {description = "Toggle fullscreen", group = "Window"}),

awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle                     ,
{description = "Toggle floating", group = "Window"}),

awful.key({ modkey, "Shift" }, "q", function (c)
	c:kill()
end, {description = "close", group = "Window"}),

-- Make master
awful.key({ modkey, }, "m", function (c)
	c:swap(awful.client.getmaster())
end, {description = "move to master", group = "Window"}),

-- Minimize and restore
awful.key({ modkey,           }, "n",
function (c)
	-- The client currently has the input focus, so it cannot be
	-- minimized, since minimized clients can't have the focus.
	c.minimized = true
end , {description = "minimize", group = "Window"}),

awful.key({ modkey, "Shift" }, "n",
function ()
	local c = awful.client.restore()
	-- Focus restored client
	if c then
		c:emit_signal(
		"request::activate", "key.unminimize", {raise = true}
		)
	end
end, {description = "restore minimized", group = "Window"})

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(globalkeys,
	-- View tag only.
	awful.key({ modkey }, "#" .. i + 9,
	function ()
		local tag = tags[i]
		if #tag:clients()==0 and not tag.selected then
			sharedtags.viewonly(tag, awful.screen.focused())
		else
			sharedtags.viewonly(tag, tag.screen)
			awful.screen.focus(tag.screen)
		end

	end,
	{description = "view tag #"..i, group = "Workspaces"}),
	-- Toggle tag display.
	awful.key({ modkey, "Control" }, "#" .. i + 9,
	function ()
		local screen = awful.screen.focused()
		local tag = tags[i]
		if tag then
			sharedtags.viewtoggle(tag, screen)
		end
	end,
	{description = "toggle tag #" .. i, group = "Workspaces"}),
	-- Move client to tag.
	awful.key({ modkey, "Shift" }, "#" .. i + 9,
	function ()
		if client.focus then
			local tag = tags[i]
			if tag then
				client.focus:move_to_tag(tag)
			end
		end
	end,
	{description = "move focused client to tag #"..i, group = "Workspaces"}),
	-- Toggle tag on focused client.
	awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
	function ()
		if client.focus then
			local tag = tags[i]
			if tag then
				client.focus:toggle_tag(tag)
			end
		end
	end,
	{description = "toggle focused client on tag #" .. i, group = "Workspaces"})
	)
end

clientbuttons = gears.table.join(
awful.button({ }, 1, function (c)
	c:emit_signal("request::activate", "mouse_click", {raise = true})
end),
awful.button({ modkey }, 1, function (c)
	c:emit_signal("request::activate", "mouse_click", {raise = true})
	awful.mouse.client.move(c)
end),
awful.button({ modkey }, 3, function (c)
	c:emit_signal("request::activate", "mouse_click", {raise = true})
	awful.mouse.client.resize(c)
end)
)
