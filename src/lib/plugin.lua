
local log = require "src.lib.log"
local event = require "src.lib.event"

local loaded = {}

local function getenv( name )
	-- uuuuuugh

	local env = setmetatable( {}, { __index = getfenv() } ) -- just for now until I can list all the Lua functions that will be safe to give over

	env.WaveLite = require "src.lib.apis.WaveLite" (name)
	env.system = require "src.lib.apis.system"
	env.util = require "src.lib.apis.util"

	return env
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
		if love.filesystem.getLastModified( v.path ) > v.time then
			plugin.reload( k )
		end
	end
end

function plugin.load( name, path )
	if not path then

		-- look in Project path, ehh, WaveLite.project_path?
		-- look in /user/plugins
		-- look in /WaveLite/plugins

	end

	if path then
		load( name, path )
	end
end

function plugin.unload( name )
	event.unbind_binder( name )
	loaded[name] = nil
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
