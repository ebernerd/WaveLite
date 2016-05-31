
local util = {}

function util.copyt( t )
	local t2 = {}
	for k, v in pairs( t ) do
		t2[k] = type( v ) == "table" and copyt( v ) or v
	end
	return t2
end

function util.compare( a, b )
	if type( a ) == "table" and type( b ) == "table" then
		for k, v in pairs( a ) do if not util.compare( v, b[k] ) then return false end end
		for k, v in pairs( b ) do if not util.compare( a[k], v ) then return false end end
		return true
	end
	return a == b
end

function util.splitlines( text )
	local lines = { "" }
	for i = 1, #text do
		if text:sub( i, i ) == "\n" then
			lines[#lines + 1] = ""
		else
			lines[#lines] = lines[#lines] .. text:sub( i, i )
		end
	end
	return lines
end

return util
