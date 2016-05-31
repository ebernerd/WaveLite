
local util = require "src.util"
local formatting = require "src.formatting"

local rendering = {}

function rendering.formatted_text_line( blocks, style, x, y )

	love.graphics.setFont( style.font )

	for i = 1, #blocks do
		love.graphics.setColor( util.lookup_style( style, blocks[i].style ) )
		love.graphics.print( blocks[i].text, x, y )

		x = x + style.font:getWidth( blocks[i].text )
	end

end

function rendering.formatted_text_lines( lines, style, x, y )

	for i = 1, #lines do
		rendering.formatted_text_line( formatting.parse( lines[i] ), style, x, y )
		y = y + style.font:getHeight()
	end

end

return rendering
