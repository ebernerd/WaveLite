
local function serialize( v, i )
	i = i or 0
	if type( v ) == "table" then
		local it = ("\t"):rep( i + 1 )
		local s = "{"
		local list = {}
		local keys = {}

		for i, v in ipairs( v ) do
			list[i] = serialize( v, i + 1 )
		end

		for k, v in pairs( v ) do
			keys[#keys + 1] = not list[k] and it .. "[" .. serialize( k, i + 1 ) .. "] = " .. serialize( v, i + 1 ) or nil
		end

		return s .. (
			(#list > 0 and " " .. table.concat( list, ", " ) or "") ..
			(#list > 0 and #keys == 0 and " " or "") ..
			(#keys > 0 and "\n" .. table.concat( keys, ";\n" ) .. ";\n" .. it:sub( 2 ) or "")
		) .. "}"
	elseif type( v ) == "string" then
		return ("%q"):format( v )
	else
		return tostring( v )
	end
end

local function unserialize( s )
	local f, err = loadstring( "return " .. tostring(s) )
	return f and select( 2, pcall( setfenv( f, {} ) ) )
end

local config = {}

config.path = "resources/configs/global.cfg"
config.cache = {}

function config.new( path )
	return setmetatable( { path = path, cache = {} }, { __index = config } )
end

function config:set( index, value )
	local t = unserialize( love.filesystem.read( self.path ) ) or {}

	self.cache[index] = value
	t[index] = value
	love.filesystem.write( self.path, serialize( t ) )
end

function config:get( index )
	if self.cache[index] then
		return self.cache[index]
	end

	local t = unserialize( love.filesystem.read( self.path ) ) or {}
	self.cache[index] = t[index]
	return t[index]
end

return config
