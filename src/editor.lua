
local UIPanel = require "src.UIPanel"
local util = require "src.util"
local cursor = require "src.cursor"
local formatting = require "src.formatting"
local text_editor = require "src.text_editor"
local rendering = require "src.rendering"
local text_window = require "src.text_window"

local DEFAULT_FONT = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 )
local PADDING_TOPLEFT = 100
local PADDING_BOTTOMRIGHT = 20
local TABS = "    "

local editor = {}

editor.files = {}
editor.workingfile = 1

editor.panel = UIPanel.body:add( UIPanel.new() )
editor.panel.enable_keyboard = true

editor.scroll_right = editor.panel:add( UIPanel.new() )
editor.scroll_bottom = editor.panel:add( UIPanel.new() )

editor.cursor_blink = {
	timer = 0;
	state = true;
}

function editor.resetCursorBlink()
	editor.cursor_blink.timer = 0
	editor.cursor_blink.state = true
end

function editor.getContentWidth()

end

function editor.getContentHeight()

end

function editor.getDisplayWidth()
	return editor.panel.width
end

function editor.getDisplayHeight()
	return editor.panel.height
end

function editor.open( filename, filecontent )
	local t = {
		filename = filename;
		lines = util.splitlines( filecontent );
		formatting = {
			lines = {};
			states = { [0] = {} };
			formatter = function(text) return util.formatText( text ) end;
		};
		cursors = { cursor.new() };
		style = {};
		scrollX = 0;
		scrollY = 0;

		onSave = function(self, content) end;
		onClose = function(self, content) end;
	}

	t.style.font = DEFAULT_FONT
	t.style.default = { 40, 40, 40 }
	formatting.format( t.lines, t.formatting )

	editor.files[#editor.files + 1] = t

	return t
end

function editor.file()
	return editor.files[editor.workingfile]
end

function editor.wheelmoved( x, y )

end

function editor.panel:onParentResized( parent )
	self.x = PADDING_TOPLEFT
	self.y = PADDING_TOPLEFT
	self.width = parent.width - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT
	self.height = parent.height - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT
end

function editor.panel:onUpdate( dt )
	editor.cursor_blink.timer = editor.cursor_blink.timer + dt

	if editor.cursor_blink.timer >= 0.5 then
		editor.cursor_blink.timer = 0
		editor.cursor_blink.state = not editor.cursor_blink.state
	end
end

function editor.panel:onDraw(mode)
	if mode == "after" then
		local file = editor.file()
		local font = file.style.font
		local fontWidth, fontHeight = font:getWidth " ", font:getHeight()
		local minl = math.floor(file.scrollX / fontHeight) + 1
		local maxl = math.min( math.ceil((file.scrollX + editor.getDisplayHeight()) / fontHeight) + 1, #file.lines )
		local ordered_cursors = cursor.sort(file.cursors)
		local i, n = minl, #ordered_cursors

		love.graphics.setColor(40, 80, 255) -- change this!

		while i <= maxl and n > 0 do
			local min, max = cursor.order(ordered_cursors[n].position, ordered_cursors[n].selection)

			if max and max[1] >= i and min[1] <= i then
				local start = min[1] == i and #file.lines[i]:sub(1, min[2] - 1):gsub("\t", TABS) + 1 or 1
				local finish = max[1] == i and #file.lines[i]:sub(1, max[2] - 1):gsub("\t", TABS) + 1 or #file.lines[i]:gsub("\t", TABS) + 1
				local x1, y1 = text_window.locationToPixels(start, i, font)
				local x2, y2 = text_window.locationToPixels(finish, i, font)

				love.graphics.rectangle("fill", x1, y1, x2 - x1, fontHeight)

				if max[1] > i then
					i = i + 1
				else
					n = n - 1
				end
			elseif not max or max[1] < i then
				n = n - 1
			else
				i = i + 1
			end
		end

		if editor.cursor_blink.state then
			love.graphics.setColor( 0, 0, 0 ) -- change this!

			for i, c in ipairs( editor.file().cursors ) do
				local cpos = cursor.clamp(c.position, file.lines)
				local cx, cy = #file.lines[cpos[1]]:sub(1, cpos[2] - 1):gsub( "\t", TABS ) + 1, cpos[1]
				local x, y = text_window.locationToPixels( cx, cy, file.style.font )

				love.graphics.line( x, y, x, y + fontHeight )
			end
		end

		love.graphics.setColor( 180, 180, 180 ) -- change this!
		love.graphics.rectangle( "line", 0, 0, editor.getDisplayWidth(), editor.getDisplayHeight() )

		for i = minl, maxl do
			rendering.formatted_text_line( formatting.parse( file.formatting.lines[i] ), editor.file().style, 0, (i-1) * font:getHeight() - file.scrollX )
		end
	end
end

function editor.panel:onTouch( x, y )
	local file = editor.file()
	local char, line = text_window.pixelsToLocation( x + file.scrollX, y + file.scrollY, file.style.font )

	file.cursors = { cursor.new( line, char ) }
	file.cursors[1].position = cursor.clamp( file.cursors[1].position, file.lines )
end

function editor.panel:onMove( x, y )
	local file = editor.file()
	local char, line = text_window.pixelsToLocation( x + file.scrollX, y + file.scrollY, file.style.font )

	file.cursors[1].selection = cursor.clamp( { line, char }, file.lines )
end

function editor.panel:onRelease( x, y )

end

function editor.panel:onKeypress( key )

	local file = editor.file()

	local isMovementKey = key == "right" or key == "up" or key == "left" or key == "down"

	if isMovementKey then
		for i = 1, #file.cursors do
			if util.isAltHeld() then
				file.cursors[i].selection = false
				file.cursors[#file.cursors + 1] = cursor.new( cursor[key](file.cursors[i].position, file.lines) )
			else
				file.cursors[i].selection = util.isShiftHeld() and (file.cursors[i].selection or file.cursors[i].position) or false
				file.cursors[i].position = cursor[key](file.cursors[i].position, file.lines)
			end
		end
		editor.resetCursorBlink()
		cursor.merge(cursor.sort(file.cursors))
	end

end

function editor.panel:onKeyrelease( key )

end

function editor.panel:onTextInput( text )
	local file = editor.file()
	text_editor.write( file.lines, file.formatting, cursor.sort(file.cursors), text )
end

function editor.load()
	editor.open( "untitled", [[
this is a string
of awesome text
that's really cool]] )
end

return editor
