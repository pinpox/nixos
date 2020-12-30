-- Minimalistic wallpaper with colored lines
function lines(cr, palette, width, height)

	-- Draw background
	local colors = require 'colors'
	cr:set_source_rgb(colors.hex( palette.base02))
	cr:paint()

	-- Set line parameters
	local line_width = 100
	cr.line_width = line_width
	cr.line_cap = 'ROUND'

	local fg_colors =  { palette.base08, palette.base09, palette.base0A,
	palette.base0B, palette.base0C, palette.base0D, palette.base0E,
	palette.base0F }

	-- math.randomseed(os.time())

	-- Iterate lines
	for y = line_width + 5, height - line_width/2, line_width + 5 do

		-- Pick a random foregraound color
		local col = fg_colors[math.random(#fg_colors)]
		cr:set_source_rgb(colors.hex(col))

		-- Randomize length
		length = math.random(width)

		-- Start
		local x = math.random(width)

		cr:move_to(x,y)
		cr:line_to(x+length, y)
		cr:stroke()

	end
end

return lines
