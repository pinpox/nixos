-- Draw the Batman symbol using the batman equation. This one is quite poor in
-- performance, you might not want to call it too often
-- https://math.stackexchange.com/questions/54506/is-this-batman-equation-for-real
--
-- (Yes, it is.)
--
function batman(cr, palette, width, height)

	-- Draw background
	local colors = require 'colors'
	cr:set_source_rgb(colors.hex( palette.base02))
	cr:paint()

	-- Set line parameters
	cr.line_width = 10
	cr.line_cap = 'ROUND'
	cr.line_join = 'CAIRO_LINE_JOIN_ROUND'

	-- Pick a random foreground color
	-- math.randomseed(os.time())

	local fg_colors =  { palette.base08, palette.base09, palette.base0A,
	palette.base0B, palette.base0C, palette.base0D, palette.base0E,
	palette.base0F }
	local col = fg_colors[math.random(#fg_colors)]
	cr:set_source_rgb(colors.hex(col))

	-- Center
	cr:translate(width/2, height/2)

	-- Helper function to draw circles at x, y
	local function dot(x,y)
		-- Scaling factor
		local a = -100
		cr:arc(x*a, y*a , 1,0 ,math.rad(350))
		cr:stroke()
	end

	-- The result of 2 hours of pain
	for x = -8, 8, 0.001 do

		dot(x ,
			2 * math.sqrt(
				-1 * math.abs( math.abs(x) - 1) *
				math.abs(3 -  math.abs(x)) /
				(
					(math.abs(x) - 1) *
					(3 -  math.abs(x))
				)
			) *
			(
				1 +  math.abs(math.abs(x) - 3) / (math.abs(x) - 3)
			) *
			math.sqrt(1 - math.pow(x / 7,2)) +
			(
				5 + 0.97 * (
					math.abs(x - 0.5) + math.abs(x + 0.5)
				) - 3 *
				( math.abs(x - 0.75) +  math.abs(x + 0.75))
			) *
			(
				1 + math.abs(1 - math.abs(x)) /
				(1 -  math.abs(x))
			)
		)

		dot(x,
			-3 * math.sqrt(1 - math.pow(x / 7,2)) *
			math.sqrt(math.abs(math.abs(x) - 4) / ( math.abs(x) - 4))
		)

		dot(x,
			math.abs(x / 2) - 0.0913722 * math.pow(x,2) - 3 +
			math.sqrt(
				1 - math.pow(math.abs(math.abs(x) - 2) - 1,2)
			)
		)

		dot(x,
			0.9 + math.sqrt(
				math.abs(math.abs(x) - 1) /
				(math.abs(x) - 1)
			) *
			(
				2.71052 + 1.5 - 0.5 *  math.abs(x) - 1.35526 *
				math.sqrt(
					4 - math.pow(math.abs(x) - 1, 2)
				)
			)
		)
	end
end
return batman
