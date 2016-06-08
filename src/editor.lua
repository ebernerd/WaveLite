
local UIPanel = require "src.UIPanel"
local util = require "src.util"
local cursor = require "src.cursor"
local formatting = require "src.formatting"
local text_editor = require "src.text_editor"
local rendering = require "src.rendering"
local text_window = require "src.text_window"
local event = require "src.event"
local scrollbar = require "src.scrollbar"
local libstyle = require "src.style"

local PADDING_TOPLEFT = 100
local PADDING_BOTTOMRIGHT = 20
local SCROLLBAR_PADDING = 3
local SCROLLBAR_SIZE = 16
local TABWIDTH = 4

local INITIAL_TEXT = [==[

--[[
	Why hello there!

	By the way, make the window fullscreen to read all this.

	Here's what needs to be done:
		Tabs are totally hacked together right now... a bunch of "    "s hardcoded in and they're just horrible.
		You need to fix tabs, as well as navigating around them.
		Having monospaced fonts would be great I tell you.

		Plugins and resources should load with a proper environment.

		Clicking needs to be an event. Dragging needs to be in the plugin API.
			selection = plugin.api.beginSelection( line, char, append )
			plugin.api.updateSelection( selection, line, char )
			plugin.api.finishSelection( selection )
		Also double click and stuff.

		Scrollbars are great but also a little glitchy and also hacked together.
		Make a nice, consistent interface that everything can use. Make the scrollbars draggable too.
		Maybe make scrollbars a part of UIPanel?

		It would be nice to have styles work like this:
		{syntax.Constant.String:"oooh this is an {#Escape;\\'}escaped{#Escape;\\'} string"}
		-> {Constant.String}, {Constant.String.Escape}, {Constant.String}
		You could also implement underlining and bold {@underline:text}, maybe even more later on
		Also maybe {@underline, @bold, syntax:Constant.Keyword;stuff}

		Events should have selectors, something like this
		event.bind("editor:key:ctrl-l#language:lua;style:blah;filename:this")

		The UI needs work. Add in stuff for adding buttons on the top.
		Add some kind of list framework on the side too.
		Need to add the bar on the bottom. It'll have methods to add stuff to the left/right sides.
		It should space them out evenly and clip middle ones if necessary

		Ctrl-z, Ctrl-y, history, shizzle like that

		Instantiatable text editor panel so you can have them all over the place. Need a 'focussed' parameter.
			UIPanel.getTextFocus(self)

		Oh this means you'll need to pass an editor object around
			event.bind("editor:key:left", function(editor)
				editor.cursor_left()
			end)
]]

if editor.isFinished() then
	print "haha you're funny"
end

]==]

local editor = {}

editor.tabs = {}
editor.workingtab = 1

editor.panel = UIPanel.new() or UIPanel.body:add( UIPanel.new() )
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
	love.graphics.setColor( libstyle.get( editor.tab().style, "editor:Scrollbar.Tray" ) )
	love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
	love.graphics.setColor( libstyle.get( editor.tab().style, "editor:Scrollbar.Slider" ) )
	love.graphics.rectangle( "fill", SCROLLBAR_PADDING, SCROLLBAR_PADDING + self.yv, self.width - 2 * SCROLLBAR_PADDING, self.heightv )
end

function editor.scroll_bottom:onDraw()
	love.graphics.setColor( libstyle.get( editor.tab().style, "editor:Scrollbar.Tray" ) )
	love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
	love.graphics.setColor( libstyle.get( editor.tab().style, "editor:Scrollbar.Slider" ) )
	love.graphics.rectangle( "fill", SCROLLBAR_PADDING + self.xv, SCROLLBAR_PADDING, self.widthv, self.height - 2 * SCROLLBAR_PADDING )
end

function editor.resetCursorBlink()
	editor.cursor_blink.timer = 0
	editor.cursor_blink.state = true
end

function editor.getContentWidth()
	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local lines = tab.lines
	local max = 0
	
	for i = 1, #lines do
		max = math.max( font:getWidth( lines[i] ), max )
	end

	return max
end

function editor.getContentHeight()
	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local lines = tab.lines

	return #lines * font:getHeight()
end

function editor.getSideLineWidth()
	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local padding2 = 2 * libstyle.get( tab.style, "editor:Lines.Padding" )
	local line_area_width = padding2

	for i = math.max( 1, #tab.lines - 9 ), #tab.lines do
		line_area_width = math.max( line_area_width, font:getWidth( i ) + padding2 )
	end

	return line_area_width
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
	if mode == "after" then
		love.graphics.setColor( libstyle.get( editor.tab().style, "editor:Foreground" ) )
		love.graphics.rectangle( "line", 0, 0, editor.getDisplayWidth(), editor.getDisplayHeight() )
		return
	end

	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local fontHeight = font:getHeight()
	local minl = math.floor(tab.scrollY / fontHeight) + 1
	local maxl = math.min( math.ceil((tab.scrollY + editor.getDisplayHeight()) / fontHeight) + 1, #tab.lines )
	local cursors = tab.cursors
	local cursors_sorted = cursor.sort( cursors )
	local i, n = minl, 1
	local line_area_width = editor.getSideLineWidth()

	local displayWidth, displayHeight = self.width, self.height
	local contentWidth, contentHeight = editor.getContentWidth(), editor.getContentHeight()
	local reqh, reqv = scrollbar.required( displayWidth, displayHeight, contentWidth, contentHeight, SCROLLBAR_SIZE )

	love.graphics.setColor( libstyle.get( tab.style, "editor:Background" ) )
	love.graphics.rectangle( "fill", 0, 0, editor.getDisplayWidth(), editor.getDisplayHeight() )

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
	love.graphics.translate( libstyle.get( tab.style, "editor:Lines.CodePadding" ) + line_area_width - tab.scrollX, -tab.scrollY )

	if editor.cursor_blink.state and not editor.is_mouse_dragging then
		love.graphics.setColor( libstyle.get( tab.style, "editor:Cursor" ) ) -- change this!

		for i, c in ipairs( cursors ) do
			local cpos = cursor.clamp( tab.lines, c.position )
			local cx, cy = cpos[3], cpos[2]
			local x, y = text_window.locationToPixels( tab.lines, cx, cy, font, font:getWidth( (" "):rep( TABWIDTH ) ) )

			love.graphics.line( x, y, x, y + fontHeight )
		end
	end

	for i = minl, maxl do
		rendering.formatted_text_line( formatting.parse( tab.formatting.lines[i] ), editor.tab().style, 0, (i-1) * font:getHeight() - tab.scrollX )
	end

	love.graphics.setColor( libstyle.get( tab.style, "editor:Background.Selected" ) ) -- change this!

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

	love.graphics.setColor( libstyle.get( tab.style, "editor:Lines.Background" ) )
	love.graphics.rectangle( "fill", 0, 0, line_area_width, self.height )

	love.graphics.push()
	love.graphics.translate( 0, -tab.scrollY )
	love.graphics.setColor( libstyle.get( tab.style, "editor:Lines.Foreground" ) )

	for i = minl, maxl do
		local x = line_area_width - font:getWidth( i ) - libstyle.get( tab.style, "editor:Lines.Padding" )
		love.graphics.print( tostring( i ), x, (i - 1) * fontHeight )
	end

	love.graphics.pop()

end

function editor.panel:onTouch( x, y )
	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX - editor.getSideLineWidth() - libstyle.get( tab.style, "editor:Lines.CodePadding" ), y + tab.scrollY, font, font:getWidth "    " )
	local new = util.isShiftHeld() and tab.cursors[#tab.cursors] or cursor.new()
	local pos = cursor.toPosition( tab.lines, line, char )
	local cursor_copy = {}

	editor.cursor_copy = cursor_copy
	editor.mouse_initial_location = cursor.clamp( tab.lines, { pos, line, char } )
	editor.is_mouse_dragging = true

	for i = 1, #tab.cursors do
		cursor_copy[i] = tab.cursors[i]
	end

	new.selection = util.isShiftHeld() and new.position or false
	new.position = editor.mouse_initial_location

	cursor.setSelection( new, new.selection )
	
	if util.isCtrlHeld() then
		tab.cursors[#tab.cursors + 1] = new
	else
		tab.cursors = { new }
		editor.cursor_copy = {}
	end

	editor.resetCursorBlink()
end

function editor.panel:onMove( x, y )
	local tab = editor.tab()
	local font = libstyle.get( tab.style, "editor:Font" )
	local char, line = text_window.pixelsToLocation( tab.lines, x + tab.scrollX - editor.getSideLineWidth() - libstyle.get( tab.style, "editor:Lines.CodePadding" ), y + tab.scrollY, font, font:getWidth "    " )
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
	editor.resetCursorBlink()
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
	editor.tab().formatting.formatter = require "resources.languages.lua"
	editor.tab().style = require "resources.styles.light"

	formatting.format( editor.tab().lines, editor.tab().formatting )

	require "resources.plugins.core"
	require "resources.plugins.custom"
end

return editor
