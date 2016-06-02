
local UIPanel = require "src.UIPanel"
local util = require "src.util"
local cursor = require "src.cursor"
local formatting = require "src.formatting"
local text_editor = require "src.text_editor"
local rendering = require "src.rendering"
local text_window = require "src.text_window"
local event = require "src.event"
local scrollbar = require "src.scrollbar"

local PADDING_TOPLEFT = 100
local PADDING_BOTTOMRIGHT = 20
local TABS = "    "
local SCROLLBAR_PADDING = 3
local SCROLLBAR_SIZE = 16

local INITIAL_TEXT = [==[

--[[
	Why hello there!

	Here's what needs to be done:
		Tabs are totally hacked together right now... a bunch of "    "s hardcoded in and they're just horrible.
		You need to fix tabs. Use an entry in a style.

		Plugins should load from a file soon.

		Clicking needs to be an event. Dragging needs to be in the plugin API.
			selection = plugin.api.beginSelection( line, char, append )
			plugin.api.updateSelection( selection, line, char )
			plugin.api.finishSelection( selection )
		Also double click and stuff.

		Scrollbars are great but also a little glitchy and also hacked together.
		Make a nice, consistent interface that everything can use. Make the scrollbars draggable too.

		It would be nice to have styles work like this:
		{Constant.String:"oooh this is an {Escape:\\'}escaped{Constant.String.Escape:\\'} string"}
		-> {Constant.String}, {Constant.String:Escape}, {Constant.String}
		You could also implement underlining and bold {@underline:text}, maybe even more later on

		The UI needs work. Add in stuff for adding buttons on the top, and add an info line on the bottom.
]]

if editor.isFinished() then
	print "haha you're funny"
end

]==]

local editor = {}

editor.tabs = {}
editor.workingtab = 1

editor.panel = UIPanel.body:add( UIPanel.new() )
editor.panel.enable_keyboard = true

editor.scroll_right = editor.panel:add( UIPanel.new() )
editor.scroll_bottom = editor.panel:add( UIPanel.new() )

editor.scroll_right.visible = false
editor.scroll_bottom.visible = false

editor.cursor_blink = {
	timer = 0;
	state = true;
}

function editor.scroll_bottom:onParentResized()
	self.x = 0
	self.y = self.parent.height - SCROLLBAR_SIZE
	self.width = self.parent.width
	self.height = SCROLLBAR_SIZE
end

function editor.scroll_right:onParentResized()
	self.x = self.parent.width - SCROLLBAR_SIZE
	self.y = 0
	self.width = SCROLLBAR_SIZE
	self.height = self.parent.height
end

function editor.scroll_right:onDraw()
	love.graphics.setColor( editor.tab().style["Scrollbar.Tray"] )
	love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
	love.graphics.setColor( editor.tab().style["Scrollbar.Slider"] )
	love.graphics.rectangle( "fill", SCROLLBAR_PADDING, SCROLLBAR_PADDING + self.yv, self.width - 2 * SCROLLBAR_PADDING, self.heightv )
end

function editor.scroll_bottom:onDraw()
	love.graphics.setColor( editor.tab().style["Scrollbar.Tray"] )
	love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
	love.graphics.setColor( editor.tab().style["Scrollbar.Slider"] )
	love.graphics.rectangle( "fill", SCROLLBAR_PADDING + self.xv, SCROLLBAR_PADDING, self.widthv, self.height - 2 * SCROLLBAR_PADDING )
end

function editor.resetCursorBlink()
	editor.cursor_blink.timer = 0
	editor.cursor_blink.state = true
end

function editor.getContentWidth()
	local tab = editor.tab()
	local font = tab.style.font
	local lines = tab.lines
	local max = 0
	
	for i = 1, #lines do
		max = math.max( font:getWidth( lines[i] ), max )
	end

	return max
end

function editor.getContentHeight()
	local tab = editor.tab()
	local font = tab.style.font
	local lines = tab.lines

	return #lines * font:getHeight()
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

	formatting.format( t.lines, t.formatting )

	editor.tabs[#editor.tabs + 1] = t

	return t
end

function editor.switchTo( tab )
	for i = 1, #editor.tabs do
		if editor.tabs[i] == tab then
			editor.workingtab = i
			return true
		end
	end
	return false
end

function editor.tab( tab )
	if tab then
		for i = 1, #editor.tabs do
			if editor.tabs[i] == tab then
				return tab
			end
		end
	end

	return editor.tabs[editor.workingtab]
end

function editor.wheelmoved( x, y )
	local tab = editor.tab()

	tab.scrollY = math.max( 0, math.min( tab.scrollY - y * 10, editor.getContentHeight() - editor.getDisplayHeight() ) )
end

function editor.panel:onParentResized( parent )
	self.x = PADDING_TOPLEFT
	self.y = PADDING_TOPLEFT
	self:resize( parent.width - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT, parent.height - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT )
end

function editor.panel:onUpdate( dt )
	editor.cursor_blink.timer = editor.cursor_blink.timer + dt

	if editor.cursor_blink.timer >= 0.5 then
		editor.cursor_blink.timer = 0
		editor.cursor_blink.state = not editor.cursor_blink.state
	end
end

function editor.panel:onDraw(mode)
	if mode == "after" then return end

	local tab = editor.tab()
	local font = tab.style.font
	local fontWidth, fontHeight = font:getWidth " ", font:getHeight()
	local minl = math.floor(tab.scrollY / fontHeight) + 1
	local maxl = math.min( math.ceil((tab.scrollY + editor.getDisplayHeight()) / fontHeight) + 1, #tab.lines )
	local cursors = tab.cursors
	local cursors_sorted = cursor.sort( cursors )
	local i, n = minl, 1

	local displayWidth, displayHeight = self.width, self.height
	local contentWidth, contentHeight = editor.getContentWidth(), editor.getContentHeight()
	local reqh, reqv = scrollbar.required( displayWidth, displayHeight, contentWidth, contentHeight, SCROLLBAR_SIZE )

	if reqh or reqv then
		local  trayWidth =  displayWidth - 2 * SCROLLBAR_PADDING - (reqv and SCROLLBAR_SIZE or 0)
		local trayHeight = displayHeight - 2 * SCROLLBAR_PADDING - (reqh and SCROLLBAR_SIZE or 0)

		editor.scroll_bottom.xv, editor.scroll_right.yv = scrollbar.getScrollbarPositions( contentWidth, contentHeight, tab.scrollX, tab.scrollY, trayWidth, trayHeight )
		editor.scroll_bottom.widthv, editor.scroll_right.heightv = scrollbar.getScrollbarSizes( displayWidth, displayHeight, contentWidth, contentHeight, trayWidth, trayHeight )

		editor.scroll_bottom.width =  trayWidth + 2 * SCROLLBAR_PADDING
		editor.scroll_right.height = trayHeight + 2 * SCROLLBAR_PADDING

		editor.scroll_bottom.visible = reqh
		editor.scroll_right.visible = reqv
	else
		editor.scroll_bottom.visible = false
		editor.scroll_right.visible = false
	end

	love.graphics.push()
	love.graphics.translate( -tab.scrollX, -tab.scrollY )

	if editor.cursor_blink.state and not editor.is_mouse_dragging then
		love.graphics.setColor( 0, 0, 0 ) -- change this!

		for i, c in ipairs( cursors ) do
			local cpos = cursor.clamp( tab.lines, c.position )
			local cx, cy = cpos[3], cpos[2]
			local x, y = text_window.locationToPixels( tab.lines, cx, cy, tab.style.font, tab.style.font:getWidth "    " )

			love.graphics.line( x, y, x, y + fontHeight )
		end
	end

	for i = minl, maxl do
		rendering.formatted_text_line( formatting.parse( tab.formatting.lines[i] ), editor.tab().style, 0, (i-1) * font:getHeight() - tab.scrollX )
	end

	love.graphics.setColor( tab.style["Background.Selected"] ) -- change this!

	while i <= maxl and n <= #cursors_sorted do
		local min, max = cursor.order( cursors_sorted[n] )

		if max[2] >= i and min[2] <= i then
			local start = min[2] == i and #tab.lines[i]:sub(1, min[3] - 1) + 1 or 1
			local finish = max[2] == i and #tab.lines[i]:sub(1, max[3] - 1) + 1 or #tab.lines[i] + 2
			local x1, y1 = text_window.locationToPixels( tab.lines, start, i, font, font:getWidth "    " )
			local x2, y2 = text_window.locationToPixels( tab.lines, finish, i, font, font:getWidth "    " )

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

	love.graphics.pop()

	love.graphics.setColor( 180, 180, 180 ) -- change this!
	love.graphics.rectangle( "line", 0, 0, editor.getDisplayWidth(), editor.getDisplayHeight() )

end

function editor.panel:onTouch( x, y )
	local tab = editor.tab()
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX, y + tab.scrollY, tab.style.font, tab.style.font:getWidth "    " )
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
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX, y + tab.scrollY, tab.style.font, tab.style.font:getWidth "    " )
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
	event.invoke( "editor:key:" ..
		(util.isCtrlHeld() and "ctrl-" or "") ..
		(util.isAltHeld() and "alt-" or "") .. 
		(util.isShiftHeld() and "shift-" or "") ..
		key, key
	)
end

function editor.panel:onKeyrelease( key )
	event.invoke( "editor:key-release:" ..
		(util.isCtrlHeld() and "ctrl-" or "") ..
		(util.isAltHeld() and "alt-" or "") .. 
		(util.isShiftHeld() and "shift-" or "") ..
		key, key
	)
end

function editor.panel:onTextInput( text )
	event.invoke( "editor:text", text )
end

function editor.load()
	local plugin = require "src.plugin"

	editor.open( "untitled", INITIAL_TEXT )
	editor.tab().formatting.formatter = formatting.newFormatter( require "resources.languages.lua" )

	for k, v in pairs( require "resources.styles.default" ) do
		editor.tab().style[k] = v
	end

	formatting.format( editor.tab().lines, editor.tab().formatting )

	event.bind( "editor:key:left", function()
		plugin.api.cursor_left( false, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:right", function()
		plugin.api.cursor_right( false, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:shift-left", function()
		plugin.api.cursor_left( true, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:shift-right", function()
		plugin.api.cursor_right( true, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:alt-left", function()
		plugin.api.cursor_left( false, true, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:alt-right", function()
		plugin.api.cursor_right( false, true, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:ctrl-left", function()
		plugin.api.cursor_left( false, false, true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:ctrl-right", function()
		plugin.api.cursor_right( false, false, true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:ctrl-shift-left", function()
		plugin.api.cursor_left( true, false, true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:ctrl-shift-right", function()
		plugin.api.cursor_right( true, false, true )
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:up", function()
		plugin.api.cursor_up( false, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:down", function()
		plugin.api.cursor_down( false, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:alt-up", function()
		plugin.api.cursor_up( false, true, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:alt-down", function()
		plugin.api.cursor_down( false, true, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:shift-up", function()
		plugin.api.cursor_up( true, false, false )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:shift-down", function()
		plugin.api.cursor_down( true, false, false )
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:return", function()
		plugin.api.write( "\n", true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:tab", function()
		plugin.api.write( "\t", true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:backspace", function()
		plugin.api.backspace( "\n", true )
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:delete", function()
		plugin.api.delete( "\t", true )
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:kp1", function()
		plugin.api.cursor_end()
		plugin.api.cursor_onscreen()
	end )
	event.bind( "editor:key:kp7", function()
		plugin.api.cursor_home()
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:ctrl-v", function()
		plugin.api.write( love.system.getClipboardText(), false )
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:ctrl-c", function()
		love.system.setClipboardText( plugin.api.text() )
	end )

	event.bind( "editor:key:ctrl-x", function()
		love.system.setClipboardText( plugin.api.text() )
		plugin.api.write( "", false )
		plugin.api.cursor_onscreen()
	end )

	event.bind( "editor:key:ctrl-a", function()
		local lines = plugin.api.count_lines()
		local text = plugin.api.count_text( lines )

		plugin.api.set_cursor( lines, text + 1, 1, 1 )
	end )

	event.bind( "editor:text", function(text)
		plugin.api.write( text, false )
	end )
end

return editor
