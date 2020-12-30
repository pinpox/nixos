-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

math.randomseed(os.time())
-- Standard awesome library
gears = require("gears")
awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
wibox = require("wibox")

-- Theme handling library
beautiful = require("beautiful")

-- Themes define colours, icons, font and wallpapers.
beautiful.init("~/.config/awesome/theme.lua")

-- Add a gap around clients
beautiful.useless_gap  = 5

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.max,
    awful.layout.suit.tile,
}

function filelog(text)
    file = io.open("awesomelog", "a")
    io.output(file)
    io.write(text, "\n")
    io.close(file)
end

-- {{{ Tags
tags = require("tags")

dofile("/home/pinpox/.config/awesome/mainmenu.lua")
dofile("/home/pinpox/.config/awesome/keybinds.lua")
dofile("/home/pinpox/.config/awesome/rules.lua")
dofile("/home/pinpox/.config/awesome/errors.lua")
dofile("/home/pinpox/.config/awesome/bar.lua")

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)
end   )

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Set keys
root.keys(globalkeys)

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
    awful.button({ }, 1, function()
        c:emit_signal("request::activate", "titlebar", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ }, 3, function()
        c:emit_signal("request::activate", "titlebar", {raise = true})
        awful.mouse.client.resize(c)
    end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            -- add margin around titlebar icons
            {
                awful.titlebar.widget.iconwidget(c),
                layout = wibox.container.margin,
                top = 5,
                left = 5,
                bottom = 5
            },
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
        {
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
                layout = wibox.container.margin,
                top = 3,
                left = 3,
                right = 3,
                bottom = 3

        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
