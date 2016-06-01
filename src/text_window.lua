
local text_window = {}

function text_window.pixelsToLocation( lines, x, y, font )
	local fWidth = font:getWidth " "
	local fHeight = font:getHeight()

	return math.floor( x / fWidth + 0.5 ) + 1, math.floor( y / fHeight ) + 1
end

function text_window.locationToPixels( lines, x, y, font )
	local fWidth = font:getWidth( lines[y]:sub( 1, x - 1 ) )
	local fHeight = font:getHeight()

	return fWidth, (y - 1) * fHeight
end

return text_window
