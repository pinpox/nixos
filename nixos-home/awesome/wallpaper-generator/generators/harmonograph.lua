
-- Simulate a harmonograph
function harmonograph(cr, palette, width, height)

	-- From Wikipedia: [...] A typical harmonograph has two pendulums that move
	-- in such a fashion, and a pen that is moved by two perpendicular rods
	-- connected to these pendulums.  Therefore, the path of the harmonograph
	-- figure is described by the parametric equations.
	--
	-- [..] in which:
	--
	-- f represents frequency
	-- p represents phase
	-- A represents amplitude
	-- d represents damping
	-- t represents time
	--
	-- The position of the pen can be calculated by:
	-- y  = A3 * sin(t*f3 + p3 ) * e^(−d * 3t) + A4 * sin( t * f4 + p4 ) * e^(−d4 * t)
	-- x  = A1 * sin(t*f1 + p1 ) * e^(−d * 1t) + A2 * sin( t * f2 + p2 ) * e^(−d2 * t)

	-- Random seed and function parameters
	-- math.randomseed(os.time())

	local f1, f2, f3, f4 = math.random(15), math.random(15), math.random(15), math.random(15)
	local d1, d2, d3, d4 = math.random() * 0.04, math.random() * 0.04, math.random() * 0.04, math.random() * 0.04
	local p1, p2, p3, p4 = (math.random() * math.pi), (math.random() * math.pi), (math.random() * math.pi), (math.random() * math.pi)

	-- Amplitude should be around half the screen size
	local Ax1, Ax2 = width / 4 + math.random(width/4), width / 4 + math.random(width/4)
	local Ay1, Ay2 = height / 4 + math.random(height/4), height / 4 + math.random(height/4)

	-- Draw background
	cr:set_source_rgb(colors.hex( palette.base02))
	cr:paint()

	-- Set line parameters
	cr:set_source_rgb(colors.hex(palette.base0D))
	cr.line_width = 2

	-- Center on screen
	cr:translate(width/2, height/2)

	-- Start position doesn't really matter, since the first line be fully transparent
	local x, y = 0, 0

	local fg_colors =  { palette.base08, palette.base09, palette.base0A,
	palette.base0B, palette.base0C, palette.base0D, palette.base0E,
	palette.base0F }

	-- Pick a random foregraound color
	local col = fg_colors[math.random(#fg_colors)]

	for t = 0, 100, 0.01 do

		-- Fade the color in using the alpha channel
		cr:set_source_rgba( colors.hex(col, t/100))

		-- Move to previous point
		cr:move_to(x, y)

		-- Calculate position and draw line to it
		x = (Ax1 * (math.exp(-d1*t) * math.sin(t*f1+p1))) + (Ax2 * (math.exp(-d2*t) * math.sin(t* f2 + p2)))
		y = (Ay1 * (math.exp(-d3*t) * math.sin(t*f3+p3))) + (Ay2 * (math.exp(-d4*t) * math.sin(t* f4 + p4)))
		cr:line_to(x, y)
		cr:stroke()
	end
end

return harmonograph

