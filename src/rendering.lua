
local util = require "src.util"
local formatting = require "src.formatting"
local libstyle = require "src.style"

local rendering = {}

function rendering.formatted_text_line( blocks, style, x, y )

	local font = libstyle.get( style, "editor:Font" )

	love.graphics.setFont( font )

	for i = 1, #blocks do
		love.graphics.setColor( libstyle.get( style, blocks[i].style ) )
		love.graphics.print( blocks[i].text, x, y )

		x = x + font:getWidth( blocks[i].text )
	end

end

return rendering
