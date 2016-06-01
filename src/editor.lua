
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

editor.tabs = {}
editor.workingtab = 1

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

function editor.open( tabname, tabcontent )
	local t = {
		tabname = tabname;
		lines = util.splitlines( tabcontent );
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

	editor.tabs[#editor.tabs + 1] = t

	return t
end

function editor.tab()
	return editor.tabs[editor.workingtab]
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
		local tab = editor.tab()
		local font = tab.style.font
		local fontWidth, fontHeight = font:getWidth " ", font:getHeight()
		local minl = math.floor(tab.scrollX / fontHeight) + 1
		local maxl = math.min( math.ceil((tab.scrollX + editor.getDisplayHeight()) / fontHeight) + 1, #tab.lines )
		local cursors = tab.cursors
		local cursors_sorted = cursor.sort( cursors )
		local i, n = minl, 1

		if editor.cursor_blink.state and not editor.is_mouse_dragging then
			love.graphics.setColor( 0, 0, 0 ) -- change this!

			for i, c in ipairs( cursors ) do
				local cpos = cursor.clamp( tab.lines, c.position )
				local cx, cy = #tab.lines[cpos[2]]:sub(1, cpos[3] - 1):gsub( "\t", TABS ) + 1, cpos[2]
				local x, y = text_window.locationToPixels( tab.lines, cx, cy, tab.style.font )

				love.graphics.line( x, y, x, y + fontHeight )
			end
		end

		love.graphics.setColor( 180, 180, 180 ) -- change this!
		love.graphics.rectangle( "line", 0, 0, editor.getDisplayWidth(), editor.getDisplayHeight() )

		for i = minl, maxl do
			rendering.formatted_text_line( formatting.parse( tab.formatting.lines[i] ), editor.tab().style, 0, (i-1) * font:getHeight() - tab.scrollX )
		end

		love.graphics.setColor(80, 160, 255, 40) -- change this!

		while i <= maxl and n <= #cursors_sorted do
			local min, max = cursor.order( cursors_sorted[n] )

			if max[2] >= i and min[2] <= i then
				local start = min[2] == i and #tab.lines[i]:sub(1, min[3] - 1):gsub("\t", TABS) + 1 or 1
				local finish = max[2] == i and #tab.lines[i]:sub(1, max[3] - 1):gsub("\t", TABS) + 1 or #tab.lines[i]:gsub("\t", TABS) + 2
				local x1, y1 = text_window.locationToPixels( tab.lines, start, i, font )
				local x2, y2 = text_window.locationToPixels( tab.lines, finish, i, font )

				love.graphics.rectangle( "fill", x1, y1, x2 - x1, fontHeight )

				if max[2] > i then
					i = i + 1
				else
					n = n + 1
				end
			elseif max[2] < i then
				n = n + 1
			else
				i = i + 1
			end
		end
	end
end

function editor.panel:onTouch( x, y )
	local tab = editor.tab()
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX, y + tab.scrollY, tab.style.font )
	local c = cursor.new()
	local pos = cursor.toPosition( tab.lines, line, char )
	local cursor_copy = {}

	editor.cursor_copy = cursor_copy
	editor.mouse_initial_location = cursor.clamp( tab.lines, { pos, line, char } )
	editor.is_mouse_dragging = true

	for i = 1, #tab.cursors do
		cursor_copy[i] = tab.cursors[i]
	end

	c.position = editor.mouse_initial_location
	
	if util.isCtrlHeld() then
		tab.cursors[#tab.cursors + 1] = c
	else
		tab.cursors = { c }
		editor.cursor_copy = {}
	end

	editor.resetCursorBlink()
end

function editor.panel:onMove( x, y )
	local tab = editor.tab()
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX, y + tab.scrollY, tab.style.font )
	local pos = cursor.toPosition( tab.lines, line, char )
	local c = cursor.new()

	tab.cursors = {}

	for i = 1, #editor.cursor_copy do
		tab.cursors[i] = editor.cursor_copy[i]
	end

	tab.cursors[#tab.cursors + 1] = c

	c.position = cursor.clamp( tab.lines, { pos, line, char } )
	cursor.setSelection( c, editor.mouse_initial_location )

	cursor.merge( tab.cursors )
end

function editor.panel:onRelease( x, y )
	editor.is_mouse_dragging = false
end

function editor.panel:onKeypress( key )

	local tab = editor.tab()
	local isMovementKey = key == "right" or key == "up" or key == "left" or key == "down"

	if isMovementKey then

		for i = 1, #tab.cursors do
			if util.isAltHeld() then
				local new = cursor.new()
				new.position = cursor[key]( tab.lines, tab.cursors[i].position )
				tab.cursors[#tab.cursors + 1] = new
			else
				local pos = util.isShiftHeld() and (tab.cursors[i].selection or tab.cursors[i].position) or false
				local c = cursor.new()

				c.position = cursor[key]( tab.lines, tab.cursors[i].position )
				cursor.setSelection( c, pos )
				tab.cursors[i] = c
			end
		end
		editor.resetCursorBlink()
		cursor.merge(tab.cursors)

	elseif key == "return" then
		text_editor.write( tab.lines, tab.formatting, tab.cursors, "\n", true )

	elseif key == "backspace" then
		for i = 1, #tab.cursors do
			if not tab.cursors[i].selection then
				tab.cursors[i].selection = cursor.left( tab.lines, tab.cursors[i].position )
			end
		end
		text_editor.write( tab.lines, tab.formatting, tab.cursors, "", true )

	elseif key == "delete" then
		for i = 1, #tab.cursors do
			if not tab.cursors[i].selection then
				tab.cursors[i].selection = cursor.right( tab.lines, tab.cursors[i].position )
			end
		end
		text_editor.write( tab.lines, tab.formatting, tab.cursors, "", true )

	elseif key == "kp1" then
		for i = 1, #tab.cursors do
			local pos = util.isShiftHeld() and (tab.cursors[i].selection or tab.cursors[i].position) or false
			local c = cursor.new()

			c.position = { cursor.toPosition( tab.lines, tab.cursors[i].position[2], math.huge ), tab.cursors[i].position[2], math.huge }
			cursor.setSelection( tab.cursors[i], pos )
			tab.cursors[i] = c
		end


	elseif key == "kp7" then
		for i = 1, #tab.cursors do
			local pos = util.isShiftHeld() and (tab.cursors[i].selection or tab.cursors[i].position) or false
			local c = cursor.new()

			c.position = { cursor.toPosition( tab.lines, tab.cursors[i].position[2], 1 ), tab.cursors[i].position[2], 1 }
			cursor.setSelection( tab.cursors[i], pos )
			tab.cursors[i] = c
		end

	elseif key == "a" then
		if util.isCtrlHeld() then
			tab.cursors = { {
				position = { cursor.toPosition( tab.lines, #tab.lines, #tab.lines[#tab.lines] + 1 ), #tab.lines, #tab.lines[#tab.lines] + 1 };
				selection = { 1, 1, 1 };
			} }
		end

	elseif key == "tab" then
		text_editor.write( tab.lines, tab.formatting, tab.cursors, "\t", true )

	elseif key == "v" then
		if util.isCtrlHeld() then
			text_editor.write( tab.lines, tab.formatting, tab.cursors, love.system.getClipboardText() )
		end

	elseif key == "c" then
		if util.isCtrlHeld() then
			local cursors = cursor.sort( tab.cursors )
			local lines = {}

			for i = 1, #cursors do
				if cursors[i].selection then
					local min, max = cursor.order( cursors[i] )
					if min[2] == max[2] then
						lines[#lines + 1] = tab.lines[min[2]]:sub( min[3], max[3] - 1 )
					else
						lines[#lines + 1] = tab.lines[min[2]]:sub( min[3] )

						for n = min[2] + 1, max[2] - 1 do
							lines[#lines + 1] = tab.lines[n]
						end

						lines[#lines + 1] = tab.lines[max[2]]:sub( 1, max[3] - 1 )
					end
				end
			end

			print( table.concat( lines, "\n" ) )

			love.system.setClipboardText( table.concat( lines, "\n" ) )
		end

	end

end

function editor.panel:onKeyrelease( key )

end

function editor.panel:onTextInput( text )
	local tab = editor.tab()
	text_editor.write( tab.lines, tab.formatting, tab.cursors, text )
end

function editor.load()
	editor.open( "untitled", [[
this is a string
of awesome text
that's really cool]] )
	editor.tab().formatting.formatter = formatting.newFormatter( require "resources.languages.lua" )

	for k, v in pairs( require "resources.styles.default" ) do
		editor.tab().style[k] = v
	end
end

return editor
