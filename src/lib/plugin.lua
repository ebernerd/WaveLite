
local log = require "src.lib.log"
local event = require "src.lib.event"
local WaveLite = require "src.WaveLite"

local loaded = {}

local function searchdir( dir, file )
	for i, f in ipairs( love.filesystem.getDirectoryItems( dir ) ) do
		if f == file then
			return dir .. "/" .. file
		end
	end
	for i, f in ipairs( love.filesystem.getDirectoryItems( dir ) ) do
		if love.filesystem.isDirectory( dir .. "/" .. f ) then
			searchdir( dir, file )
		end
	end
end

local function getenv( name )
	-- uuuuuugh

	local env = setmetatable( {}, { __index = getfenv() } ) -- just for now until I can list all the Lua functions that will be safe to give over

	env.WaveLite = require "src.lib.apis.WaveLite" (name)
	env.system = require "src.lib.apis.system" (name)
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

		if WaveLite.project then
			-- look in Project path, ehh, WaveLite.project.path?
		end

		if not path and love.filesystem.isDirectory "user/plugins" then
			for i, file in ipairs( love.filesystem.getDirectoryItems "user/plugins" ) do
				-- look in /user/plugins
			end
		end

		if not path and love.filesystem.isDirectory "plugins" then
			path = searchdir( "plugins" .. (name:find "%." and name:gsub( "%.", "/" ):match ".+/" or ""), (name:find "%." and name:gsub( ".+%.", "" ) or name) .. ".lua" )
		end
	end

	if path then
		load( name, path )
	else
		return error( "failed to load plugin '" .. name .. "' ('" .. path .. "'): not found" )
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
