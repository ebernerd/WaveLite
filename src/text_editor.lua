
local util = require "src.util"
local cursor = require "src.cursor"
local format = require "src.formatting"

local text_editor = {}

function text_editor.write( lines, formatting, cursors, text, text_assigned_to_each_cursor )

	local _newlines = util.splitlines( text )
	local one_line_per_cursor = #_newlines == #cursors and not text_assigned_to_each_cursor
	local flines = formatting.lines
	local fstate = formatting.states

	for i = 1, #cursors do
		local newlines = one_line_per_cursor and { _newlines[i] } or _newlines
		local min, max = cursor.order( cursors[i] ) -- min and max of position and selection

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
		local textdiff = (one_line_per_cursor and #newlines[1] or #text) - ( max[1] - min[1] )

		for j = 1, #cursors do
			if j ~= i then -- since the writing cursor will be updated independently

				if cursors[j].position[1] >= cursors[i].position[1] then -- if the cursor is after the editing one
					cursors[j].position = { cursors[j].position[1] + textdiff, cursor.toLineChar( lines, cursors[j].position[1] + textdiff ) }
					if cursors[j].selection then
						cursors[j].selection = { cursors[j].selection[1] + textdiff, cursor.toLineChar( lines, cursors[j].selection[1] + textdiff ) }
					end
				end

			end
		end

		-- update self cursor position
		if #newlines == 1 then
			local line, char = min[2], min[3] + #newlines[1]
			local pos = min[1] + #newlines[1]

			cursors[i] = { position = { pos, line, char }, selection = false }
		else
			local line, char = min[2] + #newlines - 1, #newlines[#newlines] + 1
			local pos = cursor.toPosition( lines, line, char )

			cursors[i] = { position = { pos, line, char }, selection = false }
		end

		format.format( lines, formatting, min[2], math.max( max[2], min[2] + #newlines - 1 ) )
	end

	if text == "" then
		cursor.merge( cursors )
	end

end

return text_editor
