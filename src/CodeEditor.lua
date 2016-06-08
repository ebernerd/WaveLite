
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

local SCROLLBARSIZE = 16
local SCROLLBARPADDING = 3
local SCROLLBARMINSIZE = 64

local function repositionEditor( editor, cursor )
	local line = cursor[2]
	local char = cursor[3]
	local font = libstyle.get( editor.style, "editor:Font" )
	local fHeight = font:getHeight()
	local space = font:getWidth " "
	local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" ) * space

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

	if xRight - editor.scrollX > editor.viewWidth then
		editor.scrollX = xRight - editor.viewWidth
	end

	if xLeft - editor.scrollX < 0 then
		editor.scrollX = xLeft
	end
end

local function mouseToPosition( editor, x, y )
	local font = libstyle.get( editor.style, "editor:Font" )
	local fontHeight = font:getHeight()
	local linesWidth = font:getWidth( #editor.lines )
	local linesPadding = libstyle.get( editor.style, "editor:Lines.Padding" )
	local linesWidthPadding = linesWidth + 2 * linesPadding
	local codePadding = libstyle.get( editor.style, "editor:Code.Padding" )
	local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
	local tabWidthPixels = font:getWidth " " * (tabWidth or 4)
	local relativeX = x - linesWidthPadding - codePadding + editor.scrollX
	local relativeY = y + editor.scrollY
	local line = math.max( 1, math.min( #editor.lines, math.floor( relativeY / fontHeight ) + 1 ) )
	local char = 0
	local tline = editor.lines[line]
	local totalWidth = 0

	if relativeX < 0 then
		return { libcursor.toPosition( editor.lines, line, 1 ), line, 1, 0 }
	end

	for i = 1, #tline do
		local w
		if tline:sub( i, i ) == "\t" then
			w = tabWidthPixels - ((totalWidth + 1) % tabWidthPixels) + 1
		else
			w = font:getWidth( tline:sub( i, i ) )
		end

		char = char + 1

		if totalWidth + w / 2 >= relativeX then
			totalWidth = totalWidth + w
			break
		end

		totalWidth = totalWidth + w
	end

	if totalWidth < relativeX then
		char = char + 1
	end

	return { libcursor.toPosition( editor.lines, line, char ), line, char, char }

end

local function rescrollX( editor )
	local font = libstyle.get( editor.style, "editor:Font" )
	local space = font:getWidth " "
	editor.scrollX = 
		math.max( 0, 
			math.min( editor.contentWidth - editor.viewWidth + 2 * space,
				editor.scrollBottomBarLeft * (editor.contentWidth - editor.viewWidth) / (editor.scrollBottom.width - SCROLLBARPADDING * 2 - editor.scrollBottomBarSize)
			)
		)
end

local function rescrollY( editor )
	editor.scrollY = 
		math.max( 0, 
			math.min( editor.contentHeight - editor.viewHeight,
				editor.scrollRightBarTop * (editor.contentHeight - editor.viewHeight) / (editor.scrollRight.height - SCROLLBARPADDING * 2 - editor.scrollRightBarSize)
			)
		)
end

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
	editor.scrollRight = editor.panel:add( UIPanel.new() )
	editor.scrollBottom = editor.panel:add( UIPanel.new() )
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

	function editor.scrollRight:onDraw( stage )
		if stage == "before" then

			love.graphics.setColor( libstyle.get( editor.style, "editor:Scrollbar.Tray" ) )
			love.graphics.rectangle( "fill", 0, 0, self.width, self.height )

			love.graphics.setColor( libstyle.get( editor.style, "editor:Scrollbar.Slider" ) )
			love.graphics.rectangle( "fill", SCROLLBARPADDING, SCROLLBARPADDING + editor.scrollRightBarTop, SCROLLBARSIZE - SCROLLBARPADDING * 2, editor.scrollRightBarSize )

		end
	end

	function editor.scrollRight:onTouch( x, y, button )
		if y < editor.scrollRightBarTop then
			editor.scrollRightBarTop = math.max( SCROLLBARPADDING, y )
			rescrollY(editor)
		elseif y > editor.scrollRightBarTop + editor.scrollRightBarSize then
			editor.scrollRightBarTop = math.min( self.height - SCROLLBARPADDING, y ) - editor.scrollRightBarSize
			rescrollY(editor)
		end

		editor.scrollRightMountPosition = y - editor.scrollRightBarTop
	end

	function editor.scrollRight:onMove( x, y, button )
		editor.scrollRightBarTop = y - editor.scrollRightMountPosition
		rescrollY( editor )
	end

	function editor.scrollBottom:onDraw( stage )
		if stage == "before" then

			love.graphics.setColor( libstyle.get( editor.style, "editor:Scrollbar.Tray" ) )
			love.graphics.rectangle( "fill", 0, 0, self.width, self.height )

			love.graphics.setColor( libstyle.get( editor.style, "editor:Scrollbar.Slider" ) )
			love.graphics.rectangle( "fill", SCROLLBARPADDING + editor.scrollBottomBarLeft, SCROLLBARPADDING, editor.scrollBottomBarSize, SCROLLBARSIZE - SCROLLBARPADDING * 2 )

		end
	end

	function editor.scrollBottom:onTouch( x, y, button )
		if x < editor.scrollBottomBarLeft then
			editor.scrollBottomBarLeft = math.max( SCROLLBARPADDING, y )
			rescrollX(editor)
		elseif y > editor.scrollBottomBarLeft + editor.scrollBottomBarSize then
			editor.scrollBottomBarLeft = math.min( self.width - SCROLLBARPADDING, y ) - editor.scrollBottomBarSize
			rescrollX(editor)
		end

		editor.scrollBottomMountPosition = x - editor.scrollBottomBarLeft
	end

	function editor.scrollBottom:onMove( x, y, button )
		editor.scrollBottomBarLeft = x - editor.scrollBottomMountPosition
		rescrollX( editor )
	end

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

	function editor.api.map( f, filter, ... )
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

	function editor.api.new_cursor( position, ID )
		editor.cursors[#editor.cursors + 1] = libcursor.new()
		editor.cursors[#editor.cursors].position = position
		repositionEditor( editor, editor.cursors[#editor.cursors].position )
		tryMerge()

		return editor.api
	end

	function editor.api.set_cursor( position, ID )
		editor.cursors[1] = libcursor.new( ID )
		editor.cursors[1].position = position
		repositionEditor( editor, editor.cursors[1].position )

		return editor.api
	end

	function editor.api.remove( cursor )
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

	function editor.api.filters.first()
		local i = 0
		return function()
			i = i + 1
			return i == 1
		end
	end

	function editor.api.filters.last()
		local i = 0
		return function()
			i = i + 1
			return i == #editor.cursors
		end
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
		elseif stage == "after" and libstyle.get( editor.style, "editor:Outline.Shown" ) then
			love.graphics.setColor( libstyle.get( editor.style, "editor:Outline.Foreground" ) )
			love.graphics.rectangle( "line", 0, 0, self.width, self.height )
		end
	end

	function editor.panel:onUpdate( dt )
		local font = libstyle.get( editor.style, "editor:Font" )
		local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
		local tabWidthPixels = font:getWidth " " * tabWidth
		local fHeight = font:getHeight()
		local showLines = libstyle.get( editor.style, "editor:Lines.Shown" )
		local codePadding = libstyle.get( editor.style, "editor:Code.Padding" )
		local linesWidthPadding = font:getWidth( #editor.lines ) + 2 * libstyle.get( editor.style, "editor:Lines.Padding" )
		local contentDisplayWidth = self.width - codePadding - (showLines and linesWidthPadding or 0)
		local space = font:getWidth " "

		editor.contentHeight = fHeight * #editor.lines
		editor.contentWidth = 0

		for i = 1, #editor.lines do
			editor.contentWidth = math.max( editor.contentWidth, util.lineWidthUpTo( editor.lines[i], #editor.lines[i] + 1, font, tabWidthPixels ) )
		end

		if editor.contentWidth > contentDisplayWidth or editor.contentHeight > self.height then
			editor.scrollBottom.visible, editor.scrollRight.visible = editor.contentWidth - SCROLLBARSIZE > contentDisplayWidth, editor.contentHeight - SCROLLBARSIZE > self.height
		else
			editor.scrollBottom.visible, editor.scrollRight.visible = false, false
		end

		editor.viewWidth = contentDisplayWidth - (editor.scrollRight.visible and SCROLLBARSIZE or 0)
		editor.viewHeight = self.height - (editor.scrollBottom.visible and SCROLLBARSIZE or 0)

		if editor.scrollRight.visible then
			editor.scrollRight.x = self.width - SCROLLBARSIZE
			editor.scrollRight.y = 0
			editor.scrollRight.width = SCROLLBARSIZE
			editor.scrollRight.height = editor.viewHeight

			editor.scrollRightBarSize = math.max( SCROLLBARMINSIZE, editor.viewHeight / editor.contentHeight * (editor.scrollRight.height - SCROLLBARPADDING * 2) )
			editor.scrollRightBarTop  = editor.scrollY / (editor.contentHeight - editor.viewHeight) * (editor.scrollRight.height - SCROLLBARPADDING * 2 - editor.scrollRightBarSize)
		end

		if editor.scrollBottom.visible then
			editor.scrollBottom.x = 0
			editor.scrollBottom.y = self.height - SCROLLBARSIZE
			editor.scrollBottom.width = editor.viewWidth + codePadding + linesWidthPadding
			editor.scrollBottom.height = SCROLLBARSIZE

			editor.scrollBottomBarSize = math.max( SCROLLBARMINSIZE, editor.viewWidth / (editor.contentWidth + space + space) * (editor.scrollBottom.width - SCROLLBARPADDING * 2) )
			editor.scrollBottomBarLeft = editor.scrollX / (editor.contentWidth + space + space - editor.viewWidth) * (editor.scrollBottom.width - SCROLLBARPADDING * 2 - editor.scrollBottomBarSize)
		end

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
			(util.isShiftHeld() and "shift-" or "") .. "touch", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
	end

	function editor.panel:onMove( x, y, button )
		libevent.invoke( "editor:move", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
	end

	function editor.panel:onRelease( x, y, button )
		libevent.invoke( "editor:release", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
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
