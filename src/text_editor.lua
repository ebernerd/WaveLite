
local util = require "src.util"
local cursor = require "src.cursor"
local format = require "src.formatting"

local text_editor = {}

function text_editor.write( lines, formatting, ordered_cursors, text, text_assigned_to_each_cursor )

	local _newlines = util.splitlines( text )
	local one_line_per_cursor = not text_assigned_to_each_cursor and #_newlines == #ordered_cursors
	local flines = formatting.lines
	local fstate = formatting.states

	for i = 1, #ordered_cursors do
		local newlines = one_line_per_cursor and { _newlines[i] } or _newlines
		local min, max = cursor.order(ordered_cursors[i].position, ordered_cursors[i].selection)
		local linediff = (max and (max[1] - min[1]) or 0) + #newlines - 1
		local chardiff = #newlines == 1 and (max and max[2] or min[2]) - min[2] + #newlines[1] or #newlines[#newlines] - min[2] + 1
		local new_position = { min[1] + linediff, #newlines == 1 and min[2] + #newlines[1] or #newlines[#newlines] + 1 }

		for n = i + 1, #ordered_cursors do
			local a, b = ordered_cursors[n].position, ordered_cursors[n].selection

			if a[1] == (max or min)[1] then
				a[2] = a[2] + chardiff
			end
			a[1] = a[1] + linediff

			if b then
				if b[1] == (max or min)[1] then
					b[2] = b[2] + chardiff
				end
				b[1] = b[1] + linediff
			end
		end

		if max then
			lines[min[1]] = lines[min[1]] .. lines[max[1]]:sub( max[2] - 1 )
			for l = min[1] + 1, max[1] do
				table.remove( lines, min[1] + 1 )
				table.remove( flines, min[1] + 1 )
				table.remove( fstate, min[1] + 1 )
			end
		end

		ordered_cursors[i] = { position = new_position, selection = false }

		if #newlines == 1 then
			lines[min[1]] = lines[min[1]]:sub( 1, min[2] - 1 ) .. newlines[1] .. lines[min[1]]:sub( min[2] )
		else
			local line = lines[min[1]]
			local lastline = newlines[#newlines] .. line:sub( min[2] )
			lines[min[1]] = line:sub( 1, min[2] - 1 ) .. newlines[1]

			for i = 2, #newlines do
				table.insert( lines, min[1] + i - 1, i < #newlines and newlines[i] or lastline )
				table.insert( flines, min[1] + i - 1, "" )
				table.insert( fstate, min[1] + i - 1, {} )
			end
		end

		format.format( lines, formatting, min[1], min[1] + linediff - 1 )

	end

end

return text_editor
