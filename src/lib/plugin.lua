
local log = require "src.lib.log"

local loaded = {}

local function getenv( name )

end

local function load( name, path )
	loaded[name] = { time = os.time(), path = path }

	local content = love.filesystem.read( path )
	local env = getenv( name )
	local f, err = loadstring( content, name )

	if f then
		local ok, err = pcall( setfenv( f, env ), path )

		if ok then
			return true
		else
			log( err )
		end
	else
		log( err )
	end

	return false
end

local plugin = {}

function plugin.update()
	for k, v in pairs( loaded ) do
		if love.filesystem.getModifiedTime( v.path ) > v.time then
			plugin.reload( k )
		end
	end
end

function plugin.load( name )
	-- find path
	load( name, path )
end

function plugin.unload( name )
	-- stuff
end

function plugin.reload( name )
	local path = loaded[name] and loaded[name].path

	if path then
		plugin.unload( name )
		load( name, path )

		return true
	else
		return false
	end
end

return plugin
