
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

local function shouldCursorBlink()
	return os.clock() % 1 < 0.5
end

local SCROLLBARSIZE = 10

local function newCodeEditor()

	local editor = {}

	editor.style = libstyle.new()
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

	editor.panel.enable_keyboard = true

	editor.api = {}

	local isMapping = false

	function editor.api.write( cursor, text )
		libtext_editor.write( editor.lines, editor.formatting, editor.cursors, cursor, text )
		editor.cursorblink = 0
	end

	function editor.api.backspace( cursor )
		cursor.selection = cursor.selection or libcursor.left( editor.lines, cursor.position )
		editor.api.write( cursor, "" )
	end

	function editor.api.delete( cursor )
		cursor.selection = cursor.selection or libcursor.right( editor.lines, cursor.position )
		editor.api.write( cursor, "" )
	end

	function editor.api.cursor_count()
		return #editor.cursors
	end

	function editor.api.map_cursors( f, filter, ... )
		local t = libcursor.sort( editor.cursors )

		isMapping = true

		for i = 1, #t do
			if not filter or filter( t[i] ) then
				f( t[i], ... )
			end
		end

		isMapping = false
	end

	function editor.api.cursor_new( position, ID )
		editor.cursors[#editor.cursors + 1] = libcursor.new()
		editor.cursors[#editor.cursors].position = position
		libcursor.merge( editor.cursors )
	end

	function editor.api.cursor_set( position, ID )
		editor.cursors[1] = libcursor.new( ID )
		editor.cursors[1].position = position
	end

	function editor.api.select_to( cursor, position )
		cursor.selection = cursor.selection or cursor.position
		cursor.position = position
		libcursor.merge( editor.cursors )
	end

	function editor.api.cursor_home( cursor )
		cursor.position = { libcursor.toPosition( editor.lines, cursor.position[2] ), cursor.position[2], 1, 1 }
		cursor.selection = false
	end

	function editor.api.cursor_end( cursor )
		cursor.position = { libcursor.toPosition( editor.lines, math.huge ), cursor.position[2], #editor.lines[cursor.position[2]] + 1, math.huge }
		cursor.selection = false
	end

	function editor.api.cursor_left( cursor, options )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		end
		libcursor.merge( editor.cursors )
	end

	function editor.api.cursor_right( cursor, options )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		end
		libcursor.merge( editor.cursors )
	end

	function editor.api.deselect( cursor )
		cursor.selection = false
	end

	function editor.api.select_line( cursor )
		local min, max = libcursor.order( cursor )

		cursor.selection = { libcursor.toPosition( editor.lines, min[2], 1 ), min[2], 1, 1 }
		cursor.position = { libcursor.toPosition( editor.lines, max[2], #editor.lines[max[2]] + 1 ), max[2], #editor.lines[max[2]] + 1, #editor.lines[max[2]] + 1 }
	end

	function editor.panel:onDraw( stage )
		local font = libstyle.get( editor.style, "editor:Font" )
		local fontHeight = font:getHeight()
		local showLines = libstyle.get( editor.style, "editor:Lines.Shown" )
		local showOutline = libstyle.get( editor.style, "editor:Outline.Shown" )
		local linesWidth = font:getWidth( #editor.lines )
		local linesPadding = libstyle.get( editor.style, "editor:Lines.Padding" )
		local linesWidthPadding = linesWidth + 2 * linesPadding
		local codePadding = libstyle.get( editor.style, "editor:Code.Padding" )
		local minLine = math.min( math.floor( editor.scrollX / fontHeight ) + 1, #editor.lines )
		local maxLine = math.min( math.ceil( (editor.scrollX + editor.viewHeight) / fontHeight ) + 1, #editor.lines )
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
				love.graphics.setColor( libstyle.get( editor.style, blocks[i].style ) )
				love.graphics.print( blocks[i].text, x, (line - 1) * fontHeight )

				x = x + font:getWidth( blocks[i].text )
			end

		end


		love.graphics.setColor( libstyle.get( editor.style, "editor:Code.Background.Selected" ) )
		while i <= maxLine do
			if cursors_sorted[n] then
				if cursors_sorted[n].selection then
					local min, max = libcursor.order( cursors_sorted[n] )

					if min[2] <= i and max[2] >= i then
						local start = min[2] < i and 0 or font:getWidth( editor.lines[i]:sub( 1, min[3] - 1 ) )
						local finish = max[2] > i and self.width or font:getWidth( editor.lines[i]:sub( 1, max[3] - 1 ) )

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

		-- draw selection (editor:Code.Background.Selected)

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

		-- draw scrollbars

		local cx, cy, fx, fy
		local fullCharWidth = libstyle.get( editor.style, "editor:Cursor.FullCharWidth" )

		love.graphics.setColor( libstyle.get( editor.style, "editor:Cursor.Foreground" ) )

		for i = 1, #editor.cursors do
			if self.focussed and editor.cursorblink % 1 < 0.5 and not editor.cursors[i].selection then
				cx, cy = editor.cursors[i].position[3], editor.cursors[i].position[2]
				fx = linesWidthPadding + codePadding - editor.scrollX + font:getWidth( editor.lines[cy]:sub( 1, cx - 1 ) )
				fy = (cy - 1) * fontHeight
				love.graphics.rectangle( "fill", fx, fy, fullCharWidth and font:getWidth( editor.lines[cy]:sub( cx, cx ) ) or 1, fontHeight )
			end
		end

		if showOutline then
			love.graphics.setColor( libstyle.get( editor.style, "editor:Outline.Foreground" ) )
			love.graphics.rectangle( "line", 0, 0, self.width, self.height )
		end

		love.graphics.print( #editor.cursors )

		--[[["editor:Code.TabWidth"] = "@editor:TabWidth";
		["editor:Code.TabForeground"] = nil;

		["editor:Lines.Background"] = rgb( 0xf5f5f5 );
		["editor:Lines.Foreground"] = rgb( 0xb0b0b0 );

		["editor:Scrollbar.Tray"] = rgb( 0xdddddd );
		["editor:Scrollbar.Slider"] = rgb( 0xbbbbbb );

	["editor:TabWidth"] = "@editor:TabWidth";

	["editor:Font"] = love.graphics.newFont( "resources/fonts/Inconsolata/Inconsolata.otf", 18 );]]

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
