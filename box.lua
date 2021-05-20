local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local prompt_widget= awful.widget.prompt()

local function osExecute(cmd)
    local fileHandle     = assert(io.popen(cmd, 'r'))
    local commandOutput  = assert(fileHandle:read('*a'))
    local returnTable    = {fileHandle:close()}
    return commandOutput,returnTable[3]            -- rc[3] contains returnCode
end

local text_widget = {
    text   = "Results will be shown here",
    id = 'results',
    widget = wibox.widget.textbox
}

local w = wibox {
    -- bg = '#1e252c',
    -- border_color = '#84bd00',
    border_width = 1,
    max_widget_size = 500,
    ontop = true,
    height = 500,
    width = 900,
    shape = function(cr, width, height)
	gears.shape.rounded_rect(cr, width, height, 3)
    end
}


w:setup {
    text_widget,
    {
	layout = wibox.container.margin,
	left = 10,
	prompt_widget,
    },
    id = 'left',
    layout = wibox.layout.fixed.vertical
}

w.visible = true

awful.placement.top(w, { margins = {top = 400}, parent = awful.screen.focused()})

awful.prompt.run{
    prompt = "<b>Search</b>: ",

    textbox = prompt_widget.widget,

    -- Called when pressing enter
    exe_callback = function(input_text)
	if not input_text or #input_text == 0 then return end
	awful.spawn("notify-send 'You selected " .. input_text.."'")
    end,

    -- Called when done (after execution or escape)
    done_callback = function()
	w.visible = false
    end,

    -- Called when typing
    changed_callback = function(input_text)
	-- TODO generate list of executables in $PATH
	--
	-- fd . $(echo $PATH | tr ":" " ") | xargs basename -a | sort -u
	--
	-- TODO filter with rg
	-- TODO colors Ansi to pango
	-- rg . --color ansi | ansifilter -M
	--
	-- Filter based on input
	-- Show choices
	w.widget.results.markup = osExecute("echo $PATH | tr ':' ' ' | /nix/store/adb5m8w4shn9bi2whnffj3hjsvgwmvr9-fd-8.2.1/bin/fd -a | rg --color ansi " .. input_text .. " | /nix/store/d13gy8jj5sy7zbrhni6nbzgp13mhpc80-ansifilter-2.18/bin/ansifilter -M")
    end
}




