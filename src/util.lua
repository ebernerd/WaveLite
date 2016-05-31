
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

function util.lookup_style( style, index )
	local parts = {}
	for part in index:gmatch "[^%.]+" do
		parts[#parts + 1] = part
	end
	for n = #parts, 1, -1 do
		local i = table.concat( parts, ".", 1, n )
		if style[i] then return style[i] end
	end
	return style.default
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

return util
