package.path = package.path .. ";/home/pinpox/.config/river-luatile/?.lua"
json = require "json"

print("river-luatile started!")
-- You can define your global state here
main_ratio = 0.65
gaps = 10
smart_gaps = false
current_layout = "rivertile"

output_layouts = { }

-- The most important function - the actual layout generator
--
-- The argument is a table with:
--  * Focused tags
--  * Window count
--  * Output width
--  * Output height
--
-- The return value must be a table with exactly `count` entries. Each entry is a table with four
-- numbers:
--  * X coordinate
--  * Y coordinate
--  * Window width
--  * Window height

argumunts = {}

function handle_metadata(args)
	return { name = output_layouts[args.output] }
end

-- We choose from one of the existing layouts defined in the table further down
function handle_layout(args)
	-- print(args.output)
	arguments = args

	-- Default to rivertile as layout for all outputs
	if output_layouts[args.output] == nil then
		output_layouts[args.output] = "rivertile"
	end
	return layouts[output_layouts[args.output]](args)
end

-- This example is a simplified version of `rivertile`
function handle_layout_rivertile(args)

	print("handle_layout() reached!")
	-- print(json.encode(args))
	local retval = {}
	if args.count == 1 then
		if smart_gaps then
			table.insert(retval, { 0, 0, args.width, args.height })
		else
			table.insert(retval, { gaps, gaps, args.width - gaps * 2, args.height - gaps * 2 })
		end
	elseif args.count > 1 then
		local main_w = (args.width - gaps * 3) * main_ratio
		local side_w = (args.width - gaps * 3) - main_w
		local main_h = args.height - gaps * 2
		local side_h = (args.height - gaps) / (args.count - 1) - gaps
		table.insert(retval, {
			gaps,
			gaps,
			main_w,
			main_h,
		})
		for i = 0, (args.count - 2) do
			table.insert(retval, {
				main_w + gaps * 2,
				gaps + i * (side_h + gaps),
				side_w,
				side_h,
			})
		end
	end
	-- print(json.encode(retval))
	return retval
end

-- Monocle layout: Show just one big window, but not fullscreen
function handle_layout_monocle(args)
	local retval = {}

	offset = 20
	gap = 5

	for i = 0, (args.count -1) do
		table.insert(retval, {
			gap + i*offset,
			gap + i*offset,
			(args.width - gap *2) -  (args.count -1) * offset,
			(args.height - gap *2) - (args.count -1) * offset,
		})
	end
	return retval
end


-- IMPORTANT: User commands send via `riverctl send-layout-cmd` are treated as lua code.
-- Active tags are stored in `CMD_TAGS` global variable.

-- Here is an example of a function that can be mapped to some key
-- Run with `riverctl send-layout-cmd luatile "toggle_gaps()"`
local gaps_alt = 0
function toggle_gaps()
	print("toggle_gaps() reached!")
	local tmp = gaps
	gaps = gaps_alt
	gaps_alt = tmp
end

-- Change output to a specific layout
function layout_switch(layout_name)
	if  layouts[layout_name] ~= nil then
		current_layout = layout_name
	end
end

-- Cycle layout of an output
function layout_cycle()
	print("CYCLING LAYOUTS")

	current_layout = output_layouts[CMD_OUTPUT]

	-- TODO this could be nicer with a cycle
	if current_layout == "rivertile" then
		current_layout = "monocle"
	elseif current_layout == "monocle" then
		current_layout = "rivertile"
	end

	output_layouts[CMD_OUTPUT] = current_layout

end

-- Add all layouts here that should be supported
layouts = {
	rivertile = handle_layout_rivertile,
	monocle = handle_layout_monocle,
	-- grid = handle_layout_grid,
}


