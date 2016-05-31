
local function findEndingMatch( text, initial, final, escape, position )
	if not final then error("hey", 2)end
	local escaped = false
	local close = "^" .. initial:gsub( "^(.*)$", final )
	local esc = escape and "^" .. initial:gsub( "^(.*)$", escape )

	while position <= #text + 1 do
		if escaped then
			escaped = false
		elseif escape and text:find( esc, position ) then
			position = select( 2, text:find( esc, position ) )
			escaped = true
		else
			local s, f = text:find( close, position )
			if s then
				return f
			end
		end

		position = position + 1
	end
end

local function longestOf( text, position, a, b, c, d, A, B, C, D )
	local t = {
		{ a, text:match( "^" .. a:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ b, text:match( "^" .. b:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ c, text:match( "^" .. c:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ d, text:match( "^" .. d:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
	}
	local l = -1
	local n = 0

	for i = 1, #t do
		if t[i][2] and #t[i][2] > l then
			n = i
		end
	end

	return n > 0 and text:match( "^" .. t[n][1], position ), n > 0 and ({A, B, C, D})[n]
end

local function formatText( text )
	return text:gsub( "\\", "\\\\" ):gsub( "{", "\\{" ):gsub( "}", "\\}" )
end

local function rgb( n )
	return { math.floor( n / 256 ^ 2 ) % 256, math.floor( n / 256 ) % 256, n % 256 }
end

return {
	copyt = copyt;
	comparet = comparet;
	findEndingMatch = findEndingMatch;
	longestOf = longestOf;
	formatText = formatText;
	lookupIndexInStyle = lookupIndexInStyle;
	rgb = rgb;
	renderText = renderText;
}
