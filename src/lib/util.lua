
local util = {}

function util.protected_table( t )
	return setmetatable( {}, { __index = t, __newindex = function( _, k, v )
		return error( "attempt to set index '" .. tostring(k) .. "' to <" .. type(v) .. ">" )
	end } )
end

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
		elseif text:sub( i, i + 1 ) == "\13\n" then
			-- do nothing
		else
			lines[#lines] = lines[#lines] .. text:sub( i, i )
		end
	end
	return lines
end

function util.roundup( n, b )
	return math.ceil( n / b ) * b
end

function util.lineWidthUpTo( line, x, font, tabWidthPixels )
	local w = 0

	for c = 1, x - 1 do
		local char = line:sub( c, c )

		if char == "\t" then
			w = util.roundup( w + 1, tabWidthPixels )
		else
			w = w + font:getWidth( char )
		end
	end

	return w
end

function util.formatText( text )
	return text:gsub( "\\", "\\\\" ):gsub( "{", "\\{" ):gsub( "}", "\\}" )
end

function util.isShiftHeld()
	return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function util.isCtrlHeld()
	return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

function util.isAltHeld()
	return love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
end

function util.findEndingMatch( text, initial, final, escape, position )
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

function util.longestOf( text, position, a, b, c, d, A, B, C, D )
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

function util.rgb( n )
	return { math.floor( n / 256 ^ 2 ) % 256, math.floor( n / 256 ) % 256, n % 256 }
end

return util
