
local text_window = {}

function text_window.pixelsToLocation( lines, x, y, font, tabWidth )
	local fHeight = font:getHeight()
	local line = math.max( math.min( #lines, math.floor( y / fHeight ) + 1 ), 1 )
	local widths = {}

	for i = 1, #lines[line] do
		local char = lines[line]:sub( i, i )
		local charWidth = char == "\t" and tabWidth or font:getWidth( char )
		widths[i] = charWidth
	end

	for i = 1, #widths do
		if x <= widths[i] / 2 then
			return i, line
		end

		x = x - widths[i]
	end

	return #lines[line] + 1, line
end

function text_window.locationToPixels( lines, x, y, font, tabWidth )
	local fWidth = 0
	local fHeight = font:getHeight()

	for i = 1, x - 1 do
		local char = lines[y]:sub( i, i )
		local charWidth = char == "\t" and tabWidth or font:getWidth( char == "" and " " or char )
		fWidth = fWidth + charWidth
	end

	return fWidth, (y - 1) * fHeight
end

return text_window
