
local text_window = {}

function text_window.pixelsToLocation(x, y, font)
	local fWidth = font:getWidth " "
	local fHeight = font:getHeight()

	return math.floor( x / fWidth + 0.2 ) + 1, math.floor( y / fHeight ) + 1
end

function text_window.locationToPixels(x, y, font)
	local fWidth = font:getWidth " "
	local fHeight = font:getHeight()

	return (x - 1) * fWidth, (y - 1) * fHeight
end

return text_window
