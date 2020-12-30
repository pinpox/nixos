local awful = require("awful")
mymainmenu = awful.menu({ items = { { "edit config", editor_cmd .. " " .. awesome.conffile },
{ "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
{ "manual", terminal .. " -e man awesome" },
{ "restart", awesome.restart },
{ "quit", function() awesome.quit() end },
} })
