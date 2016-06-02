
local editor = require "src.editor"
local cursor = require "src.cursor"
local event = require "src.event"
local text_editor = require "src.text_editor"
local util = require "src.util"
local text_window = require "src.text_window"

local plugin = {}

plugin.api = {}

function plugin.load( path )

end

function plugin.list()

end

function plugin.api.set_cursor( line, char, sline, schar )
	local tab = editor.tab()
	local new = cursor.new()

	new.position = { cursor.toPosition( tab.lines, line, char ), line, char }
	new.selection = sline and { cursor.toPosition( tab.lines, sline, schar ), sline, schar }

	tab.cursors = { new }
end

function plugin.api.new_cursor( line, char, sline, schar )
	local tab = editor.tab()
	local new = cursor.new()

	new.position = { cursor.toPosition( tab.lines, line, char ), line, char }
	new.selection = sline and { cursor.toPosition( tab.lines, sline, schar ), sline, schar }

	tab.cursors[#tab.cursors + 1] = new
end

function plugin.api.cursor_left( select, create, word )
	if word then return error "movement by word isn't implemented yet" end

	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local new = cursor.new()

		new.position = cursor.left( tab.lines, tab.cursors[i].position )

		if create then
			tab.cursors[#tab.cursors + 1] = new
		else
			cursor.setSelection( new, select and (tab.cursors[i].selection or tab.cursors[i].position) or false )
			tab.cursors[i] = new
		end
	end

	editor.resetCursorBlink()
	cursor.merge( tab.cursors )
end

function plugin.api.cursor_right( select, create, word )
	if word then return error "movement by word isn't implemented yet" end

	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local new = cursor.new()

		new.position = cursor.right( tab.lines, tab.cursors[i].position )

		if create then
			tab.cursors[#tab.cursors + 1] = new
		else
			cursor.setSelection( new, select and (tab.cursors[i].selection or tab.cursors[i].position) or false )
			tab.cursors[i] = new
		end
	end

	editor.resetCursorBlink()
	cursor.merge(tab.cursors)
end

function plugin.api.cursor_up( select, create )
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local new = cursor.new()

		if tab.cursors[i].position[2] > 1 then
			local cline, cchar = tab.cursors[i].position[2], tab.cursors[i].position[2] > 1 and tab.cursors[i].position[3] or 1
			local x, y = text_window.locationToPixels( tab.lines, cchar, cline, tab.style.font, tab.style.font:getWidth "    " )
			local char, line = text_window.pixelsToLocation( tab.lines, x, y - (cline > 1 and tab.style.font:getHeight() or 0), tab.style.font, tab.style.font:getWidth "    " )

			if x >= text_window.locationToPixels( tab.lines, #tab.lines[cline] + 1, cline, tab.style.font, tab.style.font:getWidth "    " ) then
				char = cchar
			end

			new.position = { cursor.toPosition( tab.lines, line, char ), line, char }

		else
			new.position = { 1, 1, 1 }
		end

		if create then
			tab.cursors[#tab.cursors + 1] = new
		else
			cursor.setSelection( new, select and (tab.cursors[i].selection or tab.cursors[i].position) or false )
			tab.cursors[i] = new
		end
	end

	editor.resetCursorBlink()
	cursor.merge( tab.cursors )
end

function plugin.api.cursor_down( select, create )
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local new = cursor.new()

		if tab.cursors[i].position[2] < #tab.lines then
			local cline, cchar = tab.cursors[i].position[2], tab.cursors[i].position[2] < #tab.lines and tab.cursors[i].position[3] or #tab.lines[#tab.lines] + 1
			local x, y = text_window.locationToPixels( tab.lines, cchar, cline, tab.style.font, tab.style.font:getWidth "    " )
			local char, line = text_window.pixelsToLocation( tab.lines, x, y + (cline < #tab.lines and tab.style.font:getHeight() or 0), tab.style.font, tab.style.font:getWidth "    " )

			if x >= text_window.locationToPixels( tab.lines, #tab.lines[cline] + 1, cline, tab.style.font, tab.style.font:getWidth "    " ) then
				char = cchar
			end

			new.position = { cursor.toPosition( tab.lines, line, char ), line, char }

		else
			new.position = { cursor.toPosition( tab.lines, #tab.lines, #tab.lines[#tab.lines] + 1 ), #tab.lines, #tab.lines[#tab.lines] + 1 }
		end
		
		if create then
			tab.cursors[#tab.cursors + 1] = new
		else
			cursor.setSelection( new, select and (tab.cursors[i].selection or tab.cursors[i].position) or false )
			tab.cursors[i] = new
		end
	end

	editor.resetCursorBlink()
	cursor.merge( tab.cursors )
end

function plugin.api.cursor_end()
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local pos = util.isShiftHeld() and (tab.cursors[i].selection or tab.cursors[i].position) or false
		local new = cursor.new()

		new.position = { cursor.toPosition( tab.lines, tab.cursors[i].position[2], math.huge ), tab.cursors[i].position[2], math.huge }
		cursor.setSelection( tab.cursors[i], pos )
		tab.cursors[i] = new
	end
end

function plugin.api.cursor_home()
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		local pos = util.isShiftHeld() and (tab.cursors[i].selection or tab.cursors[i].position) or false
		local new = cursor.new()

		new.position = { cursor.toPosition( tab.lines, tab.cursors[i].position[2], 1 ), tab.cursors[i].position[2], 1 }
		cursor.setSelection( tab.cursors[i], pos )
		tab.cursors[i] = new
	end
end

function plugin.api.write( text, text_per_cursor )
	local tab = editor.tab()
	text_editor.write( tab.lines, tab.formatting, tab.cursors, text, text_per_cursor )
end

function plugin.api.backspace()
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		if not tab.cursors[i].selection then
			tab.cursors[i].selection = cursor.left( tab.lines, tab.cursors[i].position )
		end
	end

	text_editor.write( tab.lines, tab.formatting, tab.cursors, "", true )
end

function plugin.api.delete()
	local tab = editor.tab()

	for i = 1, #tab.cursors do
		if not tab.cursors[i].selection then
			tab.cursors[i].selection = cursor.right( tab.lines, tab.cursors[i].position )
		end
	end
	
	text_editor.write( tab.lines, tab.formatting, tab.cursors, "", true )
end

function plugin.api.text()
	local tab = editor.tab()
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

	return table.concat( lines, "\n" )
end

function plugin.api.cursor_onscreen()
	local tab = editor.tab()
	local cursor = tab.cursors[#tab.cursors]
	local line = cursor.position[2]
	local char = cursor.position[3]
	local font = tab.style.font
	local x = font:getWidth( tab.lines[line]:sub( 1, char - 1 ):gsub( "\t", "    " ) )
	local y = (line - 1) * font:getHeight()

	if tab.scrollY > y then
		tab.scrollY = y
	elseif tab.scrollY + editor.getDisplayHeight() - font:getHeight() - 16 < y then
		tab.scrollY = y - editor.getDisplayHeight() + font:getHeight() + 16
	end
end

function plugin.api.text_line( line )
	return editor.tab().lines[line] or ""
end

function plugin.api.count_lines()
	return #editor.tab().lines
end

function plugin.api.count_text( line )
	return #(editor.tab().lines[line] or "")
end

function plugin.api.begin_mouse_selection( line, char )

end

return plugin
