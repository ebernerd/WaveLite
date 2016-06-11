
local function time()
	local n = tostring( math.floor( os.clock() * 100 ) / 100 )
	if not n:find "%." then
		return n .. ".00"
	elseif #n:match "%.(.+)" == 1 then
		return n .. "0"
	end
	return n
end

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

	print( "[" .. time() .. "]::\t" .. text )
	love.filesystem.append( self.path, "[" .. time() .. "]::\t" .. text .. "\n" )
end

return setmetatable( log, { __call = log.write } )
