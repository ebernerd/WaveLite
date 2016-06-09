
local log = {}

log.path = os.time() .. ".log"

function log:new( path )
	return setmetatable( { path = path }, { __index = self } )
end

function log:write( ... )
	local s = { ... }

	for i = 1, #s do
		s[i] = type( s[i] ) == "table" and type( s[i].tostring ) == "function" and t[i]:tostring() or tostring( s[i] )
	end

	local text = table.concat( s, ", " )

	love.filesystem.append( self.path, text .. "\n" )
end

return setmetatable( log, { __call = log.write } )
