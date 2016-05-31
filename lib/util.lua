
local function copyt( t )
	local t2 = {}
	for k, v in pairs( t ) do
		t2[k] = type(v) == "table" and copyt(v) or v
	end
	return t2
end

local function comparet( a, b )
	for k, v in pairs( a ) do
		if b[k] ~= v then return true end
	end
	for k, v in pairs( b ) do
		if a[k] ~= v then return true end
	end
end

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

local function lookupIndexInStyle(index, style)
	for part in index:gmatch "[^%.]+" do
		style = style[part] or style._Default or style
	end
	return style._Default or style
end

local function rgb( n )
	return { math.floor( n / 256 ^ 2 ) % 256, math.floor( n / 256 ) % 256, n % 256 }
end

local function renderText(text, style, x, y)
	local i = 1
	local cstack = { lookupIndexInStyle( "_Default", style ) }
	local tstack = { "" }
	local list = {}
	local escaped = false

	while i <= #text do
		if not escaped and text:sub( i, i ) == "{" then
			list[#list + 1] = { text = tstack[#tstack], colour = cstack[#cstack] }
			tstack[#tstack] = ""
			tstack[#tstack + 1] = ""

			local name = text:match( "^(%w[%.%w]*%w):", i + 1 ) or text:match( "^(%w):", i + 1 ) or "" -- error instead here?

			cstack[#cstack + 1] = lookupIndexInStyle( name, style )
			i = i + #name + 2 -- + 1 for '{' and ':'
		elseif not escaped and text:sub( i, i ) == "}" then
			list[#list + 1] = { text = tstack[#tstack], colour = cstack[#cstack] }
			tstack[#tstack] = nil
			cstack[#cstack] = nil
			i = i + 1
		elseif not escaped and text:sub( i, i ) == "\\" then
			escaped = true
			i = i + 1
		else
			escaped = false
			tstack[#tstack] = tstack[#tstack] .. text:sub( i, i )
			i = i + 1
		end

	end

	list[#list + 1] = { text = tstack[1], colour = cstack[1] }

	local font = love.graphics.getFont()

	for i =1, #list do
		love.graphics.setColor( list[i].colour )
		love.graphics.print( list[i].text, x, y )
		x = x + font:getWidth( list[i].text )
	end
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
