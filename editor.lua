
local util = require "lib.util"

local START_TEXT_LOOK_AT_START_OF_FILE = [==[
-- Aha, I see you're looking at this?

print "I changed the syntax highlighting style"

if style.better() then
	print 'Great!'
else
	print [=[ I'm so sorry ]]: ]=]
end

--[=[
	now for some [[nested]] comments
	yeah they work fine
]=]

print( 5 > 2 and true or false )
]==]

local function isShiftHeld()
	return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

local function isCtrlHeld()
	return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

local function isAltHeld()
	return love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
end

local function getLineLength( line, editor, n )
	return #line:sub( 1, n ):gsub( "\t", (" "):rep(editor.tab_spacing) )
end

local editor = {}

function editor.load()
	local windowWidth, windowHeight = love.window.getMode()

	love.keyboard.setKeyRepeat(true)

	editor.themes = {
		Default = require "resources.styles.default";
	}
	editor.languages = {
		lua = require "resources.languages.lua";
	}

	editor.theme = editor.themes.Default
	editor.lang = editor.languages.lua
	editor.font = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 )
	editor.tab_spacing = 4
	editor.padding_left = 100
	editor.padding_right = 100
	editor.padding_top = 100
	editor.padding_bottom = 100
	editor.wide_cursor = false
	editor.cursor_width = 1
	editor.scrollX = 0
	editor.scrollY = 0
	editor.contentWidth = windowWidth - editor.padding_left - editor.padding_right
	editor.contentHeight = windowHeight - editor.padding_top - editor.padding_bottom

	editor.files = {
		[1] = {
			text = require "lib.TextBody" ( START_TEXT_LOOK_AT_START_OF_FILE ),
			cursor = {
				char = 1,
				line = 1,
			},
			cursors = require "lib.CursorSystem" ();
		}
	}

	editor.cursor = {
		visible = true,
		timer = 0,
	}

	editor.workingfile = 1


	local fmt, state = require "lib.LanguageFormatter" (editor.lang)
	local f = editor.files[1]

	function f.text:formatLine(state, line)
	      return fmt(state, line)
	end
	for k, v in pairs( state ) do
	    f.text.state[k] = v
	end

	editor.files[1].text:format()
	editor.files[1].cursors:addCursor { 1, 1 }
	editor.files[1].cursors:addCursor { 2, 1 }
end

function editor.update( dt )
	editor.cursor.timer = editor.cursor.timer + dt
	if editor.cursor.timer > 0.5 then
		editor.cursor.timer = editor.cursor.timer - 0.5
		editor.cursor.visible = not editor.cursor.visible
	end
end

function editor.draw()

	local windowWidth, windowHeight = love.window.getMode()
	local wf = editor.workingfile
	local f = editor.files[wf]
	local cursor, selection = f.cursors:getDrawableCursor( 1, f.text )
	local cline = cursor[1]
	local cchar = cursor[2]
	local sline = selection and selection[1]
	local schar = selection and selection[2]
	local tabs = (" "):rep( editor.tab_spacing )
	local fontWidth = editor.font:getWidth " "
	local fontHeight = editor.font:getHeight()
	local ordered_cursors = f.cursors:getOrderedList()
	local n = #ordered_cursors
	local minline = math.floor( editor.scrollY / fontHeight ) + 1
	local maxline = math.ceil( (editor.scrollY + editor.contentHeight) / fontHeight ) + 1
	local i = minline

	love.graphics.push() -- drawing the code content
		love.graphics.setScissor( editor.padding_left - editor.scrollX, editor.padding_top - editor.scrollY, editor.contentWidth, editor.contentHeight )
		love.graphics.translate( editor.padding_left - editor.scrollX, editor.padding_top - editor.scrollY )
		love.graphics.setFont( editor.font )
		love.graphics.setBackgroundColor( editor.theme._Background )
		love.graphics.setColor( 180, 180, 180 )
		love.graphics.rectangle( "line", 0, 0, editor.contentWidth, editor.contentHeight )
		love.graphics.setColor( editor.theme._BackgroundSelected )

		while i <= maxline do
			while true do
				while ordered_cursors[n] and (not ordered_cursors[n][3] or ordered_cursors[n][3][1] < i) do
					n = n - 1 -- remove cursors whose maximum value is above the line
				end

				if ordered_cursors[n] and ordered_cursors[n][2][1] <= i then
					local start = ordered_cursors[n][2][1] == i
						and fontWidth * getLineLength(f.text:get(i), editor, ordered_cursors[n][2][2] - 1) + 1
						or 0
					local finish = ordered_cursors[n][3][1] == i
						and fontWidth * getLineLength(f.text:get(i), editor, ordered_cursors[n][3][2] - 1)
						or fontWidth * (#f.text:get(i):gsub("\t", tabs ) + 1)
					
					love.graphics.rectangle( "fill", start, (i - 1) * fontHeight, finish - start, fontHeight )

					if ordered_cursors[n][3][1] == i then
						n = n - 1
					else
						i = i + 1
					end
				else
					break
				end
			end
			i = i + 1
		end

		if editor.cursor.visible then
			for i = 1, f.cursors:getCursorCount() do
				local cursor = f.cursors:getDrawableCursor(i, f.text)
				local cline, cchar = cursor[1], cursor[2]
				local font = editor.font
				local x = font:getWidth( f.text:get(cline):sub( 1, cchar - 1 ):gsub("\t", tabs ) )
				local y = ( cline - 1 ) * editor.font:getHeight()

				love.graphics.setColor( editor.theme._Foreground )
				love.graphics.rectangle( "fill", x, y, editor.wide_cursor and editor.font:getWidth(" ") or editor.cursor_width, editor.font:getHeight() )
			end
		end

		for i = minline, maxline do
			if f.text:get(i) then
				util.renderText( f.text:getFormatted(i):gsub( "\t", tabs ), editor.theme, 0, (i-1) * fontHeight )
			end
		end

		love.graphics.setScissor()

	love.graphics.pop()
	love.graphics.print( "Col " .. cchar .. " | Line " .. cline .. " | Selection " .. (sline and "Col " .. schar .. " | Selection Line " .. sline or "None"), 10, windowHeight - fontHeight - 20 )
end

function editor.textinput( t )
	local wf = editor.workingfile
	local f = editor.files[wf]
	local cursors = f.cursors:getOrderedList()

	editor.cursor.visible = true
	editor.cursor.timer = 0

	for i = 1, #cursors do
		f.cursors:setCursor( cursors[i][1], f.text:write( t, f.cursors:order( f.cursors:getDrawableCursor( cursors[i][1], f.text ) ) ) )
	end
end

function editor.keypressed( key )
	local wf = editor.workingfile
	local f = editor.files[wf]
	local cursors = f.cursors:getOrderedList()

	editor.cursor.visible = true
	editor.cursor.timer = 0

	if key == "backspace" then
		for i = 1, #cursors do
			f.cursors:setCursor( cursors[i][1], f.text:backspace( f.cursors:order( f.cursors:getDrawableCursor( cursors[i][1], f.text ) ) ) )
		end

	elseif key == "delete" then
		for i = 1, #cursors do
			f.cursors:setCursor( cursors[i][1], f.text:delete( f.cursors:order( f.cursors:getDrawableCursor( cursors[i][1], f.text ) ) ) )
		end

	elseif key == "return" then
		for i = 1, #cursors do
			f.cursors:setCursor( cursors[i][1], f.cursors:order( f.text:write( "\n", f.cursors:getDrawableCursor( cursors[i][1], f.text ) ) ) )
		end

	elseif key == "tab" then
		for i = 1, #cursors do
			f.cursors:setCursor( cursors[i][1], f.cursors:order( f.text:write( "\t", f.cursors:getDrawableCursor( cursors[i][1], f.text ) ) ) )
		end

	elseif key == "up" then
		if isCtrlHeld() and isAltHeld() then
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:addCursor( f.cursors:getLocationUp( cursors[i][1], f.text ) )
			end
		else
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:setCursor( i, f.cursors:getLocationUp( i, f.text ), isShiftHeld() )
			end
		end

	elseif key == "down" then
		if isCtrlHeld() and isAltHeld() then
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:addCursor( f.cursors:getLocationDown( cursors[i][1], f.text ) )
			end
		else
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:setCursor( i, f.cursors:getLocationDown( i, f.text ), isShiftHeld() )
			end
		end

	elseif key == "left" then
		if isCtrlHeld() and isAltHeld() then
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:addCursor( f.cursors:getLocationLeft( cursors[i][1], f.text ) )
			end
		else
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:setCursor( i, f.cursors:getLocationLeft( i, f.text ), isShiftHeld() )
			end
		end

	elseif key == "right" then
		if isCtrlHeld() and isAltHeld() then
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:addCursor( f.cursors:getLocationRight( cursors[i][1], f.text ) )
			end
		else
			for i = 1, f.cursors:getCursorCount() do
				f.cursors:setCursor( i, f.cursors:getLocationRight( i, f.text ), isShiftHeld() )
			end
		end

	elseif key == "a" and isCtrlHeld() then
		f.cursors:setCursor { 1, 1 }
		f.cursors:setCursor( 1, { #f.text.lines, #f.text.lines[#f.text.lines] + 1 }, true )

	end
end

return editor
