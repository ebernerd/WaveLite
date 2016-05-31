
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

local editor = {}

function editor.load()
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
	editor.padding_top = 100
	editor.wide_cursor = false
	editor.cursor_width = 1

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
	editor.files[1].cursors:addCursor( 1, 1 )
end

function editor.update( dt )
	editor.cursor.timer = editor.cursor.timer + dt
	if editor.cursor.timer > 0.5 then
		editor.cursor.timer = editor.cursor.timer - 0.5
		editor.cursor.visible = not editor.cursor.visible
	end
end

function editor.draw()
	local wf = editor.workingfile
	local f = editor.files[wf]
	local cline = f.cursors:getDrawableCursor( 1, f.text )[1]
	local cchar = f.cursors:getDrawableCursor( 1, f.text )[2]

	love.graphics.setFont( editor.font )
	love.graphics.setBackgroundColor( editor.theme._Background )
	love.graphics.setColor( 255, 255, 255 )

	if editor.cursor.visible then
		local line = f.text:get(cline)
		local font = editor.font
		local x = editor.padding_left + font:getWidth( line:sub( 1, cchar - 1 ):gsub("\t", (" "):rep( editor.tab_spacing ) ) )
		local y = editor.padding_top + ( cline - 1 ) * editor.font:getHeight()

		love.graphics.setColor( editor.theme._Default )
		love.graphics.rectangle( "fill", x, y, editor.wide_cursor and editor.font:getWidth(" ") or editor.cursor_width, editor.font:getHeight() )
	end

	for i = 1, #f.text.lines do
		local line = f.text:getFormatted(i):gsub( "\t", (" "):rep(editor.tab_spacing) )
		util.renderText( line, editor.theme, editor.padding_left, editor.padding_top + (i-1) * editor.font:getHeight())
	end

	love.graphics.print( "Col " .. cchar .. " | Line " .. cline, 10, love.graphics.getHeight()-50)
end

function editor.textinput( t )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.cursor.visible = true
	editor.cursor.timer = 0

	f.cursors:setCursor( 1, f.text:write( t, f.cursors:getDrawableCursor( 1, f.text ) ) )
end

function editor.keypressed( key )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.cursor.visible = true
	editor.cursor.timer = 0

	if key == "backspace" then
		f.cursors:setCursor( 1, f.text:backspace( f.cursors:getDrawableCursor( 1, f.text ) ) )

	elseif key == "return" then
		f.cursors:setCursor( 1, f.text:write( "\n", f.cursors:getDrawableCursor( 1, f.text ) ) )

	elseif key == "tab" then
		f.cursors:setCursor( 1, f.text:write( "\t", f.cursors:getDrawableCursor( 1, f.text ) ) )

	elseif key == "up" then
		f.cursors:setCursor( 1, f.cursors:getLocationUp( 1, f.text ) )

	elseif key == "down" then
		f.cursors:setCursor( 1, f.cursors:getLocationDown( 1, f.text ) )

	elseif key == "left" then
		f.cursors:setCursor( 1, f.cursors:getLocationLeft( 1, f.text ) )

	elseif key == "right" then
		f.cursors:setCursor( 1, f.cursors:getLocationRight( 1, f.text ) )

	end
end

return editor
