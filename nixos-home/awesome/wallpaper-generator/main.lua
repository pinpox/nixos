
local lgi = require 'lgi'
local cairo = lgi.cairo

-- Set output size, e.g. your screen resolution
local width = 1920
local height = 1080

-- Colors from xresources
local palette = {}
palette.base00 = "#0b0b14"
palette.base01 = "#13131a"
palette.base02 = "#262631"
palette.base03 = "#3a3a47"
palette.base04 = "#69697c"
palette.base05 = "#babac8"
palette.base06 = "#cfcfdd"
palette.base07 = "#ffffff"
palette.base08 = "#ff4040"
palette.base09 = "#ff9326"
palette.base0A = "#ffcb65"
palette.base0B = "#9ceb4f"
palette.base0C = "#18ffe0"
palette.base0D = "#31baff"
palette.base0E = "#9d8cff"
palette.base0F = "#3f3866"

-- Require all generators
local generators = require("wp-gen")

-- Iterate through all generators and create .png files from them
for name, gen in pairs(generators) do

	print("Running generator: " .. name)

	-- Create drawing surface and context
	local surface = cairo.RecordingSurface(cairo.Content.COLOR,
	cairo.Rectangle { x = 0, y = 0, width = width, height = height })
	local cr = cairo.Context(surface)

	-- Run generator
	gen(cr, palette, width, height)

	-- Create PNG file
	surface:write_to_png('generator-' .. name .. '.png')
end
