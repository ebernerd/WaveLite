
local UIPanel = require "src.UIPanel"
local util = require "src.util"
local libcursor = require "src.cursor"
local libformatting = require "src.formatting"
local libtext_editor = require "src.text_editor"
local librendering = require "src.rendering"
local libtext_window = require "src.text_window"
local libevent = require "src.event"
local libscrollbar = require "src.scrollbar"
local libstyle = require "src.style"
local libresource = require "src.resource"

local function repositionEditor( editor, cursor )
	local line = cursor[2]
	local char = cursor[3]
	local font = libstyle.get( editor.style, "editor:Font" )
	local fHeight = font:getHeight()
	local space = font:getWidth " "
	local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" ) * space
	local showLines = libstyle.get( editor.style, "editor:Lines.Shown" )
	local codePadding = libstyle.get( editor.style, "editor:Code.Padding" )
	local linesWidthPadding = font:getWidth( #editor.lines ) + 2 * libstyle.get( editor.style, "editor:Lines.Padding" )

	local yTop = fHeight * math.max( 0, line - 2 )
	local yBottom = fHeight * math.min( #editor.lines, line + 1 )
	local xLeft = util.lineWidthUpTo( editor.lines[line], math.max( 1, char - 1 ), font, tabWidth )
	local xRight = util.lineWidthUpTo( editor.lines[line], char, font, tabWidth ) + space + space

	if yBottom - editor.scrollY > editor.viewHeight then
		editor.scrollY = yBottom - editor.viewHeight
	end
	if yTop - editor.scrollY < 0 then
		editor.scrollY = yTop
	end

	if xRight - editor.scrollX > editor.viewWidth - (showLines and linesWidthPadding or 0) - codePadding then
		editor.scrollX = xRight - editor.viewWidth + (showLines and linesWidthPadding or 0) + codePadding
	end

	if xLeft - editor.scrollX < 0 then
		editor.scrollX = xLeft
	end
end

local function mouseToPosition( editor, x, y )
	
end

local SCROLLBARSIZE = 10

local function newCodeEditor()

	local editor = {}

	editor.style = libresource.load( "style", "light" )
	editor.panel = UIPanel.new()
	editor.lines = { "" }
	editor.language = "plain text"
	editor.formatting = {
		lines = { "" };
		states = { [0] = {} };
		formatter = function( line ) return util.formatText( line ) end;
	}
	editor.focussed = false
	editor.scrollX = 0
	editor.scrollY = 0
	editor.contentWidth = 0
	editor.contentHeight = libstyle.get( editor.style, "editor:Font" ):getHeight()
	editor.viewWidth = 0
	editor.viewHeight = 0
	editor.scrollRight = false
	editor.scrollBottom = false
	editor.cursors = {
		libcursor.new();
	}
	editor.cursorblink = 0
	editor.langname = "plain text"
	editor.stylename = "light"

	editor.panel.enable_keyboard = true

	editor.api = {}
	editor.api.filters = {}
	editor.api.position = {}

	local isMapping = false
	local shouldMerge = true

	local function tryMerge()
		if isMapping then
			shouldMerge = true
		else
			libcursor.merge( editor.cursors )
		end
	end

	function editor.api.resetCursorBlink()
		editor.cursorblink = 0
		return editor.api
	end

	function editor.api.setLanguage( name )
		editor.langname = name
		editor.formatting.formatter = libresource.load( "language", name )
		libformatting.format( editor.lines, editor.formatting )

		return editor.api
	end

	function editor.api.language()
		return editor.langname
	end

	function editor.api.setStyle( name )
		editor.stylename = name
		editor.style = libresource.load( "style", name )
		libformatting.format( editor.lines, editor.formatting )

		return editor.api
	end

	function editor.api.style()
		return editor.stylename
	end

	function editor.api.write( cursor, text )
		libtext_editor.write( editor.lines, editor.formatting, editor.cursors, cursor, text )
		editor.cursorblink = 0
		repositionEditor( editor, cursor.position )
		tryMerge()

		return editor.api
	end

	function editor.api.backspace( cursor )
		cursor.selection = cursor.selection or libcursor.left( editor.lines, cursor.position )
		editor.api.write( cursor, "" )

		return editor.api
	end

	function editor.api.delete( cursor )
		cursor.selection = cursor.selection or libcursor.right( editor.lines, cursor.position )
		editor.api.write( cursor, "" )

		return editor.api
	end

	function editor.api.copy( cursor, copyLine )
		if cursor.selection then
			local min, max = libcursor.order( cursor )

			if min[2] == max[2] then
				return editor.lines[min[2]]:sub( min[3], max[3] - 1 )
			else
				return editor.lines[min[2]]:sub( min[3] ) .. "\n" .. table.concat( editor.lines, "\n", min[2] + 1, max[2] - 1 ) .. (max[2] > min[1] + 1 and "\n" or "") .. editor.lines[max[2]]:sub( 1, max[3] - 1 )
			end
		elseif copyLine then
			return editor.lines[cursor.position[2]]
		end
	end

	function editor.api.cursor_count()
		return #editor.cursors
	end

	function editor.api.map_cursors( f, filter, ... )
		local t = {} -- libcursor.sort( editor.cursors )

		for i = 1, #editor.cursors do
			t[i] = editor.cursors[i]
		end

		isMapping = true

		for i = 1, #t do
			if not filter or filter( t[i] ) then
				f( t[i], ... )
			end
		end

		if shouldMerge then
			libcursor.merge( editor.cursors )
		end

		isMapping = false

		return editor.api
	end

	function editor.api.cursor_new( position, ID )
		editor.cursors[#editor.cursors + 1] = libcursor.new()
		editor.cursors[#editor.cursors].position = position
		repositionEditor( editor, editor.cursors[#editor.cursors].position )
		tryMerge()

		return editor.api
	end

	function editor.api.cursor_set( position, ID )
		editor.cursors[1] = libcursor.new( ID )
		editor.cursors[1].position = position
		repositionEditor( editor, editor.cursors[1].position )

		return editor.api
	end

	function editor.api.cursor_remove( cursor )
		for i = #editor.cursors, 1, -1 do
			if editor.cursors[i] == cursor then
				table.remove( editor.cursors, i )
			end
		end

		return editor.api
	end

	function editor.api.select_to( cursor, position )
		cursor.selection = cursor.selection or cursor.position
		cursor.position = position
		repositionEditor( editor, cursor.position )
		tryMerge()

		return editor.api
	end

	function editor.api.cursor_home( cursor, options )
		if options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = { libcursor.toPosition( editor.lines, options.full and 1 or cursor.position[2], 1 ), options.full and 1 or cursor.position[2], 1, 1 }
			editor.cursorblink = 0
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = { libcursor.toPosition( editor.lines, options.full and 1 or cursor.position[2], 1 ), options.full and 1 or cursor.position[2], 1, 1 }
			cursor.selection = false
			editor.cursorblink = 0
		end

		repositionEditor( editor, cursor.position )
		tryMerge()

		return editor.api
	end

	function editor.api.cursor_end( cursor, options )
		if options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = { libcursor.toPosition( editor.lines, options.full and #editor.lines or cursor.position[2], math.huge ), options.full and #editor.lines or cursor.position[2], #editor.lines[options.full and #editor.lines or cursor.position[2]] + 1, math.huge }
			editor.cursorblink = 0
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = { libcursor.toPosition( editor.lines, options.full and #editor.lines or cursor.position[2], math.huge ), options.full and #editor.lines or cursor.position[2], #editor.lines[options.full and #editor.lines or cursor.position[2]] + 1, math.huge }
			cursor.selection = false
			editor.cursorblink = 0
		end

		repositionEditor( editor, cursor.position )
		tryMerge()

		return editor.api
	end

	function editor.api.cursor_up( cursor, options )
		local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor.up( editor.lines, tabWidth, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor.up( editor.lines, tabWidth, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor.up( editor.lines, tabWidth, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return editor.api
	end

	function editor.api.cursor_down( cursor, options )
		local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor.down( editor.lines, tabWidth, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor.down( editor.lines, tabWidth, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor.down( editor.lines, tabWidth, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return editor.api
	end

	function editor.api.cursor_left( cursor, options )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return editor.api
	end

	function editor.api.cursor_right( cursor, options )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return editor.api
	end

	function editor.api.deselect( cursor )
		cursor.selection = false
	end

	function editor.api.select_line( cursor )
		local min, max = libcursor.order( cursor )

		cursor.selection = { libcursor.toPosition( editor.lines, min[2], 1 ), min[2], 1, 1 }
		cursor.position = { libcursor.toPosition( editor.lines, max[2], #editor.lines[max[2]] + 1 ), max[2], #editor.lines[max[2]] + 1, #editor.lines[max[2]] + 1 }

		-- repositionEditor( editor, cursor.position ) ?

		tryMerge()

		return editor.api
	end

	function editor.api.show( position )
		repositionEditor( editor, position )

		return editor.api
	end

	function editor.api.filters.eofline( cursor )
		return cursor.position[3] == #editor.lines[cursor.position[2]] + 1
	end

	function editor.api.filters.sofline( cursor )
		return cursor.position[3] == 1
	end

	function editor.api.filters.count_start( i )
			i = i or 1
		return function()
			i = i - 1
			return i >= 0
		end
	end

	function editor.api.filters.count_end( i )
		i = #editor.cursors - (i or 1)
		return function()
			i = i - 1
			return i < 0
		end
	end

	editor.api.filters.count = editor.api.filters.count_start

	function editor.panel:onDraw( stage )
		if stage == "before" then
			librendering.code( editor, self )
		end
	end

	function editor.panel:onUpdate( dt )
		if editor.contentWidth > self.width or editor.contentHeight > self.height then
			editor.scrollRight, editor.scrollBottom = editor.contentWidth - SCROLLBARSIZE > self.width, editor.contentHeight - SCROLLBARSIZE > self.height
		end

		editor.viewWidth = self.width - (editor.scrollRight and SCROLLBARSIZE or 0)
		editor.viewHeight = self.height - (editor.scrollBottom and SCROLLBARSIZE or 0)

		editor.cursorblink = editor.cursorblink + dt
	end

	function editor.panel:onFocus()
		self.focussed = true
	end

	function editor.panel:onUnFocus()
		self.focussed = false
	end

	function editor.panel:onTouch( x, y, button )
		self:focus()
		editor.cursorblink = 0
		libevent.invoke( "editor:" ..
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") .. 
			(util.isShiftHeld() and "shift-" or "") .. "touch", editor.api, x, y, button ) -- change to use char coords
	end

	function editor.panel:onMove( x, y, button )
		libevent.invoke( "editor:move", editor.api, x, y, button ) -- change to use char coords
	end

	function editor.panel:onRelease( x, y, button )
		libevent.invoke( "editor:release", editor.api, x, y, button ) -- change to use char coords
	end

	function editor.panel:onKeypress( key )
		if self.focussed then
			libevent.invoke( "editor:key:" .. 
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") .. 
			(util.isShiftHeld() and "shift-" or "") .. key, editor.api )
		end
	end

	function editor.panel:onKeyrelease( key )
		if self.focussed then
			libevent.invoke( "editor:key-release:" ..
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") ..
			(util.isShiftHeld() and "shift-" or "") .. key, editor.api, key )
		end
	end

	function editor.panel:onTextInput( text )
		if self.focussed then
			libevent.invoke( "editor:text", editor.api, text )
		end
	end

	return editor

end

return newCodeEditor
