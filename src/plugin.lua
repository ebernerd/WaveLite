
local editor = require "src.editor"
local cursor = require "src.cursor"
local event = require "src.event"
local text_editor = require "src.text_editor"
local util = require "src.util"

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

		if create then
			new.position = cursor.left( tab.lines, tab.cursors[i].position )
			tab.cursors[#tab.cursors + 1] = new
		else
			new.position = cursor.left( tab.lines, tab.cursors[i].position )
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

		if create then
			new.position = cursor.right( tab.lines, tab.cursors[i].position )
			tab.cursors[#tab.cursors + 1] = new
		else
			new.position = cursor.right( tab.lines, tab.cursors[i].position )
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

		if create then
			new.position = cursor.up( tab.lines, tab.cursors[i].position )
			tab.cursors[#tab.cursors + 1] = new
		else
			new.position = cursor.up( tab.lines, tab.cursors[i].position )
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

		if create then
			new.position = cursor.down( tab.lines, tab.cursors[i].position )
			tab.cursors[#tab.cursors + 1] = new
		else
			new.position = cursor.down( tab.lines, tab.cursors[i].position )
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

function plugin.api.count_lines()
	return #editor.tab().lines
end

function plugin.api.count_text( line )
	return #(editor.tab().lines[line] or "")
end

return plugin
