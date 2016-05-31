
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

	love.graphics.setFont( editor.font )
	love.graphics.setBackgroundColor( editor.theme._Background )
	love.graphics.setColor( 255, 255, 255 )

	if editor.cursor.visible then
		local line = f.text:get(f.cursor.line)
		local font = editor.font
		local x = editor.padding_left + font:getWidth( line:sub( 1, f.cursor.char - 1 ):gsub("\t", (" "):rep( editor.tab_spacing ) ) )
		local y = editor.padding_top + ( f.cursor.line - 1 ) * editor.font:getHeight()

		love.graphics.setColor( editor.theme._Default )
		love.graphics.rectangle( "fill", x, y, editor.font:getWidth(" "), editor.font:getHeight() )
	end

	for i=1, #f.text.lines do
		local line = f.text:getFormatted(i):gsub( "\t", (" "):rep(editor.tab_spacing) )
		util.renderText( line, editor.theme, 100, 100+(i-1)*editor.font:getHeight())
	end

	love.graphics.print( "Col " .. f.cursor.char .. " | Line " .. f.cursor.line, 10, love.graphics.getHeight()-50)
end

function editor.textinput( t )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.cursor.visible = true
	editor.cursor.timer = 0

	f.text:write( t, {f.cursor.line, f.cursor.char} )
	f.cursor.char = f.cursor.char + 1
end

function editor.keypressed( key )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.cursor.visible = true
	editor.cursor.timer = 0

	if key == "backspace" then
		if f.cursor.line > 1 then
			if f.cursor.char > 0 then
				f.cursor.char = f.cursor.char - 1
			end
			f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. f.text:get(f.cursor.line):sub(f.cursor.char+1, #f.text:get(f.cursor.line)))
		else
			if f.cursor.char > 1 then
				f.cursor.char = f.cursor.char - 1
			end

			f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. f.text:get(f.cursor.line):sub(f.cursor.char+1, #f.text:get(f.cursor.line)))
		end
		if f.cursor.char == 0 and f.cursor.line > 1 then
			local t = f.text:get(f.cursor.line)
			f.cursor.line = f.cursor.line - 1
			f.cursor.char = #f.text:get(f.cursor.line)+1
			f.text:set(f.cursor.line, f.text:get(f.cursor.line)..t)
			f.text:remove(f.cursor.line+1)
		end
	elseif key == "return" then
		--print(f.text:get(f.cursor.line), f.cursor.char, f.cursor.line, #f.text:get(f.cursor.line))
		f.text:insert(f.cursor.line+1, f.text:get(f.cursor.line):sub(f.cursor.char, #f.text:get(f.cursor.line)))

		f.text:set( f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char))
		f.cursor.line = f.cursor.line + 1
		f.cursor.char = 1
	elseif key == "tab" then
		f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. "\t" .. f.text:get(f.cursor.line):sub(f.cursor.char) )
		f.cursor.char = f.cursor.char + 1
	elseif key == "up" then
		if f.cursor.line > 1 then
			if f.cursor.char == #f.text:get(f.cursor.line)+1 then
				f.cursor.char = #f.text:get(f.cursor.line-1)+1
			end
			f.cursor.line = f.cursor.line - 1
		end
	elseif key == "down" then
		if #f.text.lines >= f.cursor.line + 1 then
			f.cursor.line = f.cursor.line + 1
			if f.cursor.char == #f.text:get(f.cursor.line-1)+1 then
				f.cursor.char = #f.text:get(f.cursor.line)+1
			elseif f.cursor.char >= #f.text:get(f.cursor.line)+1 then
				f.cursor.char = #f.text:get(f.cursor.line)+1
			end
		end
	elseif key == "left" then
		if f.cursor.char == 1 and f.cursor.line > 1 then
			f.cursor.line = f.cursor.line -1
			f.cursor.char = #f.text:get(f.cursor.line)+1
		else
			f.cursor.char = f.cursor.char-1
		end
	elseif key == "right" then
		if f.cursor.char <= #f.text:get(f.cursor.line) then
			f.cursor.char = f.cursor.char + 1
		else
			if #f.text.lines > f.cursor.line then
				f.cursor.char = 1
				f.cursor.line = f.cursor.line + 1
			end
		end
	end
end

return editor
