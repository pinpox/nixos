local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local prompt_widget= awful.widget.prompt()

local border_color = "#eeeeee"
local match_color = "#00ff00"

local function osExecute(cmd)
    local fileHandle     = assert(io.popen(cmd, 'r'))
    local commandOutput  = assert(fileHandle:read('*a'))
    local returnTable    = {fileHandle:close()}
    return commandOutput,returnTable[3]            -- rc[3] contains returnCode
end

local optionsTextWidget = {
    text   = "Options will be shown here",
    id = 'listoptions',
    widget = wibox.widget.textbox
}


local selectedTextWidget = {
    text   = "Matched will be shown here",
    id = 'selectedoption',
    widget = wibox.widget.textbox
}

local w = wibox {
    -- bg = '#1e252c',
    border_color = border_color,
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
    {
	layout = wibox.container.margin,
	left = 10,
	prompt_widget,
	id = 'wprompt',
    },

    {
	layout = wibox.container.margin,
	left = 10,
	optionsTextWidget ,
	id = 'optionsid',
    },
    selectedTextWidget,
    id = 'left',
    layout = wibox.layout.fixed.vertical
}



w.visible = true

awful.placement.top(w, { margins = {top = 400}, parent = awful.screen.focused()})


local allexecutables = osExecute('find $(echo $PATH | tr ":" " ") | xargs basename -a | sort -u' )

local selectedCommand = ""

awful.prompt.run{
    prompt = "<b>Run</b>: ",

    textbox = prompt_widget.widget,

    -- Called when pressing enter
    exe_callback = function(input_text)
	if not input_text or #input_text == 0 then return end
	awful.spawn("notify-send 'You selected " .. selectedCommand .."'")
    end,

    -- Called when done (after execution or escape)
    done_callback = function()
	w.visible = false
    end,

    -- Called when typing
    changed_callback = function(input_text)

	-- Split lines
	local grepExes= {}
	for line in allexecutables:gmatch("([^\n]*)\n?") do

	    -- find lines beginning with input. Not fuzzy for now
	    if line:find("^"..input_text ) ~= nil then
		table.insert (grepExes, line)
	    end
	end

	if #grepExes == 0 then
	    w.widget.listoptions.text = "none left"
	    return
	end

	selectedCommand = table.remove(grepExes, 1)

	-- First opiton shown as match
	--
	local keys = ""
	for k,v in pairs(w) do
	    keys = keys .. ", " .. k
	end


	w.widget.selectedoption.markup= keys -- '<span foreground="'..match_color..'">' .. selectedCommand .. '</span>'

	-- Rest listed as remaining options
	-- w.widget.listoptions.text = table.concat(grepExes, "\n")
	-- w.widget.listoptions.text = "test"
	-- w:get_children_by_id("options_id")[1].text = "testiresntirsent"

    end
}




