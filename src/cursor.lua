
local cursor = {}

function cursor.new( l, c )
	return { position = l and ( type( l ) == "table" and l or { l, c } ) or { 1, 1 }, selection = false }
end

function cursor.order( a, b )
	if b then
		local a_larger = a.position[1] > b.position[1] or a.position[1] == b.position[1] and a.position[2] > b.position[2]
		return a_larger and b or a, a_larger and a or b
	else
		return a
	end
end

function cursor.smaller( a, b )
	return a.position[1] < b.position[1] and a or a.position[1] == b.position[1] and a.position[2] < b.position[2] and a or b
end

function cursor.larger( a, b )
	return a.position[1] < b.position[1] and b or a.position[1] == b.position[1] and a.position[2] < b.position[2] and b or a
end

function cursor.ordered( cursor_list )
	local t = {}

	for i = 1, #cursor_list do
		t[#t + 1] = { cursor_list[i], i }
	end

	table.sort( t, function( a, b )
		return a[1].position[1] > b[1].position[1] or a[1].position[1] == b[1].position[1] and a[1].position[2] > b[1].position[2]
	end )

	return t
end

function cursor.merge( cursor_list )
	local ordered = cursor.ordered( cursor_list )

	for i = #ordered - 1, 1, -1 do
		local a, b = ordered[i], ordered[i + 1]
	end

	return ordered
end

return cursor
