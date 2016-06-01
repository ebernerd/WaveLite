
local cursor = {}

function cursor.new()
	return { position = { 1, 1, 1 }, selection = false }
end

function cursor.order( c ) -- takes a cursor
	if c.selection then
		local p_larger = c.position[1] > c.selection[1]
		return p_larger and c.selection or c.position, p_larger and c.position or c.selection
	else
		return c.position, c.position
	end
end

function cursor.sort( list )
	local copy = {}

	for i = 1, #list do
		copy[i] = list[i]
	end

	table.sort( copy, function( a, b )
		return a.position[1] < b.position[1]
	end )

	-- debugging!
	assert( not copy[2] or copy[1].position[1] <= copy[2].position[1], "swap the sorting function" )

	return copy
end

function cursor.min( c ) -- takes a cursor
	return c.selection and (c.position[1] < c.selection[1] and c.position or c.selection) or c.position
end

function cursor.max( c ) -- takes a cursor
	return c.selection and (c.position[1] > c.selection[1] and c.position or c.selection) or c.position
end

function cursor.smaller( a, b ) -- takes two cursor positions
	return a[1] < b[1] and a or b
end

function cursor.larger( a, b ) -- takes two cursor positions
	return a[1] > b[1] and a or b
end

function cursor.merge( cursors ) -- takes a {cursor}
	for i = #cursors, 1, -1 do
		for n = i - 1, 1, -1 do
			local minI, maxI = cursor.order( cursors[i] )
			local minN, maxN = cursor.order( cursors[n] )

			if minI[1] <= maxN[1] and minN[1] <= maxI[1] then print( "Merging a cursor bitches" )
				local min = cursor.smaller( minI, minN )
				local max = cursor .larger( maxI, maxN )
				
				cursors[n] = { position = min, selection = min[1] ~= max[1] and max or false }
				table.remove( cursors, i )
				break
			end
		end
	end
end

function cursor.toLineChar( lines, position )
	local line = 1

	while lines[line] and position > #lines[line] + 1 do
		position = position - (#lines[line] + 1)
		line = line + 1
	end

	return line, math.min( position, #lines[line] + 1 )
end

function cursor.toPosition( lines, line, char )
	line = math.max( 1, math.min( line, #lines ) )

	local position = 0

	for i = 1, line - 1 do
		position = position + #lines[i] + 1
	end

	return position + math.min( math.max( 1, char ), #lines[line] + 1 )
end

function cursor.clamp( lines, c ) -- takes a cursor position or selection
	return { c[1], cursor.toLineChar( lines, c[1] ) }
end

function cursor.up( lines, c )
	return c[2] > 1 and { cursor.toPosition( lines, c[2] - 1, c[3] ), c[2] - 1, c[3] } or { 1, 1, 1 }
end

function cursor.down( lines, c )
	if c[2] < #lines then
		return { cursor.toPosition( lines, c[2] + 1, c[3] ), c[2] + 1, c[3] }
	else
		return { cursor.toPosition( lines, c[2], #lines[c[2]] + 1 ), c[2], #lines[c[2]] + 1 }
	end
end

function cursor.left( lines, c )
	if c[3] > 1 then
		return { c[1] - 1, c[2], math.min( c[3], #lines[c[2]] + 1 ) - 1 }
	elseif c[2] > 1 then
		return { cursor.toPosition( lines, c[2] - 1, #lines[c[2] - 1] + 1 ), c[2] - 1, #lines[c[2] - 1] + 1 }
	else
		return c
	end
end

function cursor.right( lines, c )
	if c[3] <= #lines[c[2]] then
		return { c[1] + 1, c[2], c[3] + 1 }
	elseif c[2] < #lines then
		return { c[1] + 1, c[2] + 1, 1 }
	else
		return c
	end
end

return cursor
