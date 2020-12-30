-- Pink floyd like prisma using defined palette
vector = require "generators.lib.vector"

function prisma(cr, palette, width, height)

	-- Draw background
	local colors = require 'colors'
	cr:set_source_rgb(colors.hex(palette.base00))
	cr:paint()

	-- Set line parameters
	local line_width = 5
	cr.line_width = line_width
	cr.line_cap = 'ROUND'


	-- Side length of the triangle
	local x = width/3

	-- Height of the triangle
	local h = math.sqrt(math.pow(x, 2) - math.pow((x/2), 2))

	-- Translate to the tip of the triangle to make the calculations easier
	cr:translate(width/2, (height/2) - h/1.5 )

	-- Draw triangle
	cr:set_source_rgb(colors.hex(palette.base07))
	cr:move_to(0,0)
	cr:line_to(x/2,h)
	cr:line_to(-x/2,h)
	cr:line_to(0,0)
	cr:stroke()

	-- helper line
	local c_2 = vector.new(-x/4, h/2)


	-- Incoming ray
	-- The original pink floyd logo's incoming beam is about 15 degrees angled
	-- towards flat the x-axis
	local b1 = width/2 / math.sin(math.rad(width/2)) * math.sin(math.rad(15))

	cr:move_to(-width/2, h/2 - b1)
	cr:line_to(c_2:unpack())

	cr:set_source_rgb(1, 1, 1)
	cr:stroke()

	-- Inner and right beam

	local inner_colors = { palette.base02, palette.base03, palette.base04,
	palette.base05, palette.base06, palette.base07}

	local beam_colors =  { palette.base08, palette.base09, palette.base0A,
	palette.base0B, palette.base0D, palette.base0E }

	for i=1,6 do

		-- Inner triangle segment
		cr:set_source_rgb(colors.hex(inner_colors[i]))
		cr:move_to(
			x/6 + ((6 - i) * (x/36)),
			h/3 + ((6 - i) * (h/18))
		)

		cr:line_to(c_2:unpack())

		cr:line_to(
			x/6 + ((7 - i) * (x/36)),
			h/3 + ((7 - i) * (h/18))
		)
		cr:fill()

		-- Out beam segment
		cr:set_source_rgb(colors.hex(beam_colors[7-i]))

		-- left side
		cr:move_to(
			x/6 + ((6 - i) * (x/36)),
			h/3 + ((6 - i) * (h/18))
		)

		cr:line_to(
			x/6 + ((7 - i) * (x/36)),
			h/3 + ((7 - i) * (h/18))
		)

		-- right side
		cr:line_to(
			width/2,
			h/2 - ((b1 - b1/6 * i) + b1/2)
		)

		cr:line_to(
			width/2,
			h/2 - ((b1 - b1/6 * (i + 1)) + b1/2)
		)
		cr:fill()

	end
end


return prisma
