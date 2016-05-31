
local cursor = {}

function cursor.new( l, c )
	return { position = l and ( type( l ) == "table" and l or { l, c } ) or { 1, 1 }, selection = false }
end

function cursor.order( a, b )
	if b then
		local a_larger = a[1] > b[1] or a[1] == b[1] and a[2] > b[2]
		return a_larger and b or a, a_larger and a or b
	else
		return a
	end
end

function cursor.setSelection( c, s )
	c.selection = s or false
	return c
end

function cursor.equal( a, b )
	return a[1] == b[1] and a[2] == b[2]
end

function cursor.smaller( a, b )
	return a[1] < b[1] and a or a[1] == b[1] and a[2] < b[2] and a or b
end

function cursor.larger( a, b )
	return a[1] < b[1] and b or a[1] == b[1] and a[2] < b[2] and b or a
end

function cursor.sort( cursor_list )
	table.sort( cursor_list, function( A, B )
		local a, b = cursor.order( A.position, A.selection ), cursor.order( B.position, B.selection )
		return a[1] < b[1] or a[1] == b[1] and a[2] < b[2]
	end )

	return cursor_list
end

function cursor.merge( cursor_list ) -- TODO!
	for i = #cursor_list - 1, 1, -1 do
		local a, b = cursor_list[i], cursor_list[i + 1]
	end

	return cursor_list
end

function cursor.clamp( cursor, lines )
	local line, char = cursor[1], cursor[2]
	if line > #lines then
		line = #lines
	end
	if char > #lines[line] then
		char = #lines[line] + 1
	end
	return { line, char }
end

function cursor.up( c, lines )
	return c[1] > 1 and {c[1] - 1, c[2]} or { 1, 1 }
end

function cursor.down( c, lines )
	return c[1] < #lines and {c[1] + 1, c[2]} or {c[1], #lines[#lines] + 1}
end

function cursor.left( c, lines )
	return c[2] > 1 and { c[1], math.min( c[2], #lines[c[1]] + 1 ) - 1 } or c[1] > 1 and { c[1] - 1, #lines[c[1] - 1] + 1 } or { 1, 1 }
end

function cursor.right( c, lines )
	return c[2] <= #lines[c[1]] and { c[1], c[2] + 1 } or c[1] < #lines and { c[1] + 1, 1 } or { c[1], #lines[#lines] + 1 }
end

return cursor
