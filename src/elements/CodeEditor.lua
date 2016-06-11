
local UIPanel = require "src.elements.UIPanel"
local util = require "src.lib.util"
local libcursor = require "src.lib.cursor"
local libformatting = require "src.lib.formatting"
local librendering = require "src.lib.rendering"
local libevent = require "src.lib.event"
local libstyle = require "src.style"
local libresource = require "src.lib.resource"
local newEditorAPI = require "src.lib.apis.editor"

local SCROLLBARSIZE = 20
local SCROLLBARPADDING = 3
local SCROLLBARMINSIZE = 64
local SCROLLSPEED = 35

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

	if relativeX < -codePadding then
		return { libcursor.toPosition( editor.lines, line, 1 ), line, 1, 1 }
	elseif relativeX < 0 then
		relativeX = 0
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
	editor.scrollX = math.floor(
		math.max( 0, 
			math.min( editor.contentWidth + 2 * space - editor.viewWidth,
				editor.scrollBottomBarLeft * ((editor.contentWidth + 2 * space) - editor.viewWidth) / (editor.scrollBottom.width - SCROLLBARPADDING * 2 - editor.scrollBottomBarSize)
			)
		)
	)
end

local function rescrollY( editor )
	editor.scrollY = math.floor(
		math.max( 0, 
			math.min( editor.contentHeight - editor.viewHeight,
				editor.scrollRightBarTop * (editor.contentHeight - editor.viewHeight) / (editor.scrollRight.height - SCROLLBARPADDING * 2 - editor.scrollRightBarSize)
			)
		)
	)
end

local function newCodeEditor( mode, title, content, path )

	local editor = UIPanel.new()

	editor.type = "editor"
	editor.mode = mode
	editor.path = path
	editor.opentime = os.time()
	editor.title = title or "untitled"
	editor.style = libresource.load( "style", "core:light" )
	editor.lines = util.splitlines( content or "" )
	editor.formatting = {
		lines = { "" };
		states = { [0] = {} };
		formatter = function( line ) return util.formatText( line ) end;
	}
	editor.enable_keyboard = true
	editor.scrollX = 0
	editor.scrollY = 0
	editor.contentWidth = 0
	editor.contentHeight = libstyle.get( editor.style, "editor:Font" ):getHeight()
	editor.viewWidth = 0
	editor.viewHeight = 0
	editor.scrollRight = editor:add( UIPanel.new() )
	editor.scrollBottom = editor:add( UIPanel.new() )
	editor.scrollRightBarTop = 0
	editor.scrollRightBarSize = 0
	editor.scrollBottomBarLeft = 0
	editor.scrollBottomBarSize = 0
	editor.cursors = {
		libcursor.new();
	}
	editor.cursorblink = 0
	editor.langname = "core:plain text"
	editor.stylename = "core:light"
	editor.clicked = false

	editor.api = newEditorAPI( editor )

	libformatting.format( editor.lines, editor.formatting )

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
			editor.scrollRightBarTop = math.max( 0, y - SCROLLBARPADDING )
			rescrollY(editor)
		elseif y > editor.scrollRightBarTop + editor.scrollRightBarSize then
			editor.scrollRightBarTop = math.min( self.height, y ) - SCROLLBARPADDING - editor.scrollRightBarSize
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
			editor.scrollBottomBarLeft = math.max( 0, x - SCROLLBARPADDING )
			rescrollX(editor)
		elseif x > editor.scrollBottomBarLeft + editor.scrollBottomBarSize then
			editor.scrollBottomBarLeft = math.min( self.width, x ) - SCROLLBARPADDING - editor.scrollBottomBarSize
			rescrollX(editor)
		end

		editor.scrollBottomMountPosition = x - editor.scrollBottomBarLeft
	end

	function editor.scrollBottom:onMove( x, y, button )
		editor.scrollBottomBarLeft = x - editor.scrollBottomMountPosition
		rescrollX( editor )
	end

	function editor:onDraw( stage )
		if stage == "before" then
			librendering.code( editor )
		elseif stage == "after" and libstyle.get( editor.style, "editor:Outline.Shown" ) then
			love.graphics.setColor( libstyle.get( editor.style, "editor:Outline.Foreground" ) )
			love.graphics.rectangle( "line", 0, 0, self.width, self.height )
		end
	end

	function editor:onUpdate( dt )
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
			editor.scrollBottom.visible, editor.scrollRight.visible = editor.contentWidth > contentDisplayWidth - SCROLLBARSIZE, editor.contentHeight > self.height - SCROLLBARSIZE
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

		if self.path and love.filesystem.isFile( self.path ) and love.filesystem.getLastModified( self.path ) > self.opentime then
			self.opentime = os.time()
			libevent.invoke( "editor:file-modified", self.api )
		end
	end

	function editor:onFocus()
		if not love.keyboard.hasTextInput() then
			love.keyboard.setTextInput( true )
		end
	end

	function editor:onUnFocus()
		love.keyboard.setTextInput( false )
	end

	function editor:onTouch( x, y, button )
		self:focus()
		editor.cursorblink = 0
		libevent.invoke( "editor:" ..
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") .. 
			(util.isShiftHeld() and "shift-" or "") ..
			(editor.clicked and os.clock() - editor.clicked < 0.2 and "double-" or "") ..
			"touch", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
		editor.clicked = (not editor.clicked or os.clock() - editor.clicked >= 0.2) and os.clock() or false
	end

	function editor:onMove( x, y, button )
		libevent.invoke( "editor:move", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
	end

	function editor:onRelease( x, y, button )
		libevent.invoke( "editor:release", editor.api, mouseToPosition( editor, x, y ), button ) -- change to use char coords
	end

	function editor:onKeypress( key )
		if self.focussed then
			libevent.invoke( "editor:key:" .. 
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") .. 
			(util.isShiftHeld() and "shift-" or "") .. key, editor.api )
		end
	end

	function editor:onKeyrelease( key )
		if self.focussed then
			libevent.invoke( "editor:key-release:" ..
			(util.isCtrlHeld() and "ctrl-" or "") ..
			(util.isAltHeld() and "alt-" or "") ..
			(util.isShiftHeld() and "shift-" or "") .. key, editor.api, key )
		end
	end

	function editor:onTextInput( text )
		if self.focussed then
			libevent.invoke( "editor:text", editor.api, text )
		end
	end

	function editor:onWheelMoved( x, y )
		self.scrollY = math.max( 0, math.min( self.scrollY - y * SCROLLSPEED, self.contentHeight - self.viewHeight ) )
		self.scrollX = math.max( 0, math.min( self.scrollX - x * SCROLLSPEED, self.contentWidth - self.viewWidth ) )
	end

	return editor

end

return newCodeEditor
