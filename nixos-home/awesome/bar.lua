-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
awful.button({ }, 1, function(t) t:view_only() end),
awful.button({ modkey }, 1, function(t)
	if client.focus then
		client.focus:move_to_tag(t)
	end
end),
awful.button({ }, 3, awful.tag.viewtoggle),
awful.button({ modkey }, 3, function(t)
	if client.focus then
		client.focus:toggle_tag(t)
	end
end),

-- Scroll on taglist
awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
awful.button({ }, 1, function (c)
	if c == client.focus then
		c.minimized = true
	else
		c:emit_signal(
		"request::activate",
		"tasklist",
		{raise = true}
		)
	end
end),
awful.button({ }, 3, function()
	awful.menu.client_list({ theme = { width = 250 } })
end),
awful.button({ }, 4, function ()
	awful.client.focus.byidx(1)
end),
awful.button({ }, 5, function ()
	awful.client.focus.byidx(-1)
end))

-- Create a textclock widget
mytextclock = wibox.widget.textclock("%H:%M ")
month_calendar = awful.widget.calendar_popup.month({
	bg = "#00fff0",
})

month_calendar:attach( mytextclock, "br" )

mytextclock:connect_signal("button::press",
function(_, _, _, button)
	if button == 1 then month_calendar:toggle() end
end)

awful.screen.connect_for_each_screen(function(s)
	-- Assign tags to the newly connected screen here,
	-- if desired:
	--sharedtags.viewonly(tags[4], s)

	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
	awful.button({ }, 1, function () awful.layout.inc( 1) end),
	awful.button({ }, 3, function () awful.layout.inc(-1) end),
	awful.button({ }, 4, function () awful.layout.inc( 1) end),
	awful.button({ }, 5, function () awful.layout.inc(-1) end)))

	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist {
		screen  = s,
		-- Only show tags that are not empty
		filter  = awful.widget.taglist.filter.noempty,
		buttons = taglist_buttons
	}


	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist {
		screen  = s,
		filter  = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
		layout = {
			spacing = 5,
			layout  = wibox.layout.flex.horizontal
		},
		widget_template = {
			{
				{
					{
						{
							id     = 'icon_role',
							widget = wibox.widget.imagebox,
						},
						margins = 3,
						widget  = wibox.container.margin,
					},
					{
						id     = 'text_role',
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.fixed.horizontal,
				},
				left  = 10,
				right = 10,
				widget = wibox.container.margin
			},
			id     = 'background_role',
			widget = wibox.container.background,
		},
	}


	function custom_shape(cr, width, height)
		cr:move_to(10,0)
		cr:line_to(width -10,0)
		cr:line_to(width -10, height- 10)
		cr:line_to(10,height-10)
		cr:close_path()
	end

	-- Create the wibox
	s.mywibox = awful.wibox({
		position = "bottom",
		screen = s,
		height = 40,
		shape = custom_shape,
		-- width = 900,
	})


	-- Add widgets to the wibox
	s.mywibox:setup {
		{
			-- opacity = 0,
			layout = wibox.layout.align.horizontal,
			{
				{
					-- Left widgets
					layout = wibox.layout.fixed.horizontal,
					s.mytaglist,
				},
				margins = 5,
				widget = wibox.container.margin,

			},
			-- Middle widget
			{
				s.mytasklist,

				margins = 5,
				widget = wibox.container.margin,
			},
			{
				{
					-- Right widgets
					layout = wibox.layout.fixed.horizontal,
					spacing = 30,
					wibox.widget.systray(),
					mytextclock,
					s.mylayoutbox,
				},

				margins = 5,
				widget  = wibox.container.margin,
			},

		},
		bottom = 10,
		left = 10,
		right = 10,
		widget = wibox.container.margin,
	}
end)
