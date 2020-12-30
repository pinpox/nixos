local M = {}

local function interpolate(r1, g1, b1, r2, g2, b3, step)
	-- print(r)
	-- print(g)
	-- print(b)
	return r, g, b
end

local function hex (hex, alpha)
	local hash,redColor,greenColor,blueColor=hex:match('(.)(..)(..)(..)')
	redColor, greenColor, blueColor = tonumber(redColor, 16)/255, tonumber(greenColor, 16)/255, tonumber(blueColor, 16)/255
	redColor, greenColor, blueColor = math.floor(redColor*100)/100, math.floor(greenColor*100)/100, math.floor(blueColor*100)/100
	if alpha == nil then
		return redColor, greenColor, blueColor
	end
	return redColor, greenColor, blueColor, alpha
end

M.hex = hex
M.interpolate = interpolate
return M


