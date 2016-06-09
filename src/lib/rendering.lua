
local UIPanel = require "src.elements.UIPanel"
local util = require "src.lib.util"
local libcursor = require "src.lib.cursor"
local libformatting = require "src.lib.formatting"
local libstyle = require "src.style"

local rendering = {}

function rendering.code( editor, self )
	local font = libstyle.get( editor.style, "editor:Font" )
	local fontHeight = font:getHeight()
	local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
	local tabShown = libstyle.get( editor.style, "editor:Tabs.Shown" )
	local tabColour = libstyle.get( editor.style, "editor:Tabs.Foreground" )
	local tabWidthPixels = font:getWidth " " * tabWidth
	local showLines = libstyle.get( editor.style, "editor:Lines.Shown" )
	local linesWidth = font:getWidth( #editor.lines )
	local linesPadding = libstyle.get( editor.style, "editor:Lines.Padding" )
	local linesWidthPadding = linesWidth + 2 * linesPadding
	local codePadding = libstyle.get( editor.style, "editor:Code.Padding" )
	local minLine = math.min( math.floor( editor.scrollY / fontHeight ) + 1, #editor.lines )
	local maxLine = math.min( math.ceil( (editor.scrollY + editor.viewHeight) / fontHeight ) + 1, #editor.lines )
	local cursors_sorted = libcursor.sort( editor.cursors )
	local n = 1
	local i = 1

	love.graphics.setFont( font )
	love.graphics.setColor( libstyle.get( editor.style, "editor:Code.Background" ) )
	love.graphics.rectangle( "fill", 0, 0, self.width, self.height )

	love.graphics.push()
	love.graphics.translate( linesWidthPadding + codePadding - editor.scrollX, -editor.scrollY )

	for line = minLine, maxLine do

		local blocks = libformatting.parse( editor.formatting.lines[line] )
		local x = 0

		for i = 1, #blocks do
			local colour = libstyle.get( editor.style, blocks[i].style )

			love.graphics.setColor( colour )

			for c = 1, #blocks[i].text do
				local char = blocks[i].text:sub( c, c )

				if char == "\t" then
					if tabShown then
						love.graphics.setColor( tabColour )
						love.graphics.line( x, (line - 1) * fontHeight, x, line * fontHeight - 1 )
						love.graphics.setColor( colour )
					end
					x = util.roundup( x + 1, tabWidthPixels )
				else
					love.graphics.print( char, x, (line - 1) * fontHeight )
					x = x + font:getWidth( char )
				end
			end
		end

	end


	love.graphics.setColor( libstyle.get( editor.style, "editor:Code.Background.Selected" ) )
	while i <= maxLine do
		if cursors_sorted[n] then
			if cursors_sorted[n].selection then
				local min, max = libcursor.order( cursors_sorted[n] )

				if min[2] <= i and max[2] >= i then
					local start = min[2] < i and 0 or util.lineWidthUpTo( editor.lines[i], min[3], font, tabWidthPixels )
					local finish = max[2] > i and self.width or util.lineWidthUpTo( editor.lines[i], max[3], font, tabWidthPixels )

					love.graphics.rectangle( "fill", start, (i - 1) * fontHeight, finish - start, fontHeight )

					if max[2] == i then
						n = n + 1
					else
						i = i + 1
					end
				elseif max[2] < i then
					n = n + 1
				else
					i = i + 1
				end
			else
				n = n + 1
			end
		else
			break
		end
	end

	local cx, cy, fx, fy, fw
	local fullCharWidth = libstyle.get( editor.style, "editor:Cursor.FullCharWidth" )
	local col = libstyle.get( editor.style, "editor:Cursor.Foreground" )

	love.graphics.setColor( col[1], col[2], col[3], fullCharWidth and 40 or 255 )

	for i = 1, #editor.cursors do
		if self.focussed and editor.cursorblink % 1 < 0.5 then
			cx, cy = editor.cursors[i].position[3], editor.cursors[i].position[2]
			fx = util.lineWidthUpTo( editor.lines[cy], cx, font, tabWidthPixels )
			fy = (cy - 1) * fontHeight
			fw = fullCharWidth and (editor.lines[cy]:sub( cx, cx ) == "\t" and util.roundup( fx + 1, tabWidthPixels ) - fx or font:getWidth( cx > #editor.lines[cy] and " " or editor.lines[cy]:sub( cx, cx ) )) or 1
			love.graphics.rectangle( "fill", fx, fy, fw, fontHeight )
		end
	end

	love.graphics.pop()

	if showLines then
		love.graphics.setColor( libstyle.get( editor.style, "editor:Lines.Background" ) )
		love.graphics.rectangle( "fill", 0, 0, linesWidthPadding, editor.viewHeight )

		love.graphics.push()
		love.graphics.translate( 0, -editor.scrollY )
		love.graphics.setColor( libstyle.get( editor.style, "editor:Lines.Foreground" ) )

		for line = minLine, maxLine do
			love.graphics.print( line, linesWidth + linesPadding - font:getWidth( line ), (line - 1) * fontHeight )
		end

		love.graphics.pop()
	end
end

return rendering
