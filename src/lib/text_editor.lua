
local util = require "src.lib.util"
local libcursor = require "src.lib.cursor"
local libformatting = require "src.lib.formatting"

local text_editor = {}

function text_editor.write( lines, formatting, cursors, cursor, text )
	local min, max = libcursor.order( cursor ) -- min and max of position and selection
	local flines = formatting.lines
	local fstate = formatting.states
	local newlines = util.splitlines( text )

	-- cut out selected text
	if max[1] ~= min[1] then -- if the selection and position aren't the same
		lines[min[2]] = lines[min[2]]:sub( 1, min[3] - 1 ) .. lines[max[2]]:sub( max[3] ) -- combine the first and last lines
		for i = max[2], min[2] + 1, -1 do -- remove other lines
			table.remove( lines, i )
			table.remove( flines, i )
			table.remove( fstate, i )
		end
	end

	-- write new text
	if #newlines == 1 then -- write the one line of text
		lines[min[2]] = lines[min[2]]:sub( 1, min[3] - 1 ) .. newlines[1] .. lines[min[2]]:sub( min[3] )
	else
		local add_to_last_line = lines[min[2]]:sub( min[3] ) -- newlines[#newlines] should have the remainder of this line added on
	
		lines[min[2]] = lines[min[2]]:sub( 1, min[3] - 1 ) .. newlines[1] -- the cursor line should be cut up to the cursor and have the first line added on

		for i = 2, #newlines do
			local index = min[2] + i - 1

			table.insert( lines, index, newlines[i] .. ( i == #newlines and add_to_last_line or "" ) ) -- add the new line in
			table.insert( flines, index, "" )
			table.insert( fstate, index, {} )
		end
	end

	-- update other cursor positions

	local cpos = cursor.position[1]
	local textdiff = #text + min[1] - max[1]

	for i = 1, #cursors do
		if cursors[i] == cursor then -- since the writing cursor will be updated independently

			local line = min[2] + #newlines - 1
			local char = #newlines == 1 and min[3] + #newlines[1] or #newlines[#newlines] + 1
			local pos = #newlines == 1 and min[1] + #newlines[1] or libcursor.toPosition( lines, line, char )

			cursor.position = { pos, line, char, char }
			cursor.selection = false

		else

			if cursors[i].position[1] >= cpos then -- if the cursor is after the editing one
				cursors[i].position = { cursors[i].position[1] + textdiff, libcursor.toLineChar( lines, cursors[i].position[1] + textdiff ) }
			end

			if cursors[i].selection and cursors[i].selection[1] >= cpos then
				cursors[i].selection = { cursors[i].selection[1] + textdiff, libcursor.toLineChar( lines, cursors[i].selection[1] + textdiff ) }
			end

		end
	end

	libformatting.format( lines, formatting, min[2], math.max( max[2], min[2] + #newlines - 1 ) )
end

return text_editor
