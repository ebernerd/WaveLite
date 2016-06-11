
--[[
	system
		string platform()
		void copy(string text)
		string paste()
]]

local util = require "src.lib.util"

local function newSystemAPI()
	local system = {}

	function system.open_url( url )
		if type( url ) ~= "string" then return error( "expected string url, got " .. type( url ) ) end

		return love.system.openURL( url )
	end

	function system.read_file( file )
		if type( file ) ~= "string" then return error( "expected string file, got " .. type( file ) ) end

		return love.filesystem.exists( file ) and love.filesystem.read( file )
	end

	function system.write_file( file, text )
		if type( file ) ~= "string" then return error( "expected string file, got " .. type( file ) ) end
		if type( text ) ~= "string" then return error( "expected string text, got " .. type( text ) ) end

		return not love.filesystem.isDirectory( file ) and love.filesystem.write( file, text ) or error( "attempt to write to directory '" .. tostring( file ) .. "'" )
	end

	function system.list_files( path )
		return love.filesystem.isDirectory( path ) and love.filesystem.getDirectoryItems( path )
	end

	function system.platform()
		return love.system.getOS()
	end

	function system.copy( text )
		if type( text ) ~= "string" then return error( "expected string text, got " .. type( text ) ) end

		return love.system.setClipboardText( text )
	end

	function system.paste()
		return love.system.getClipboardText()
	end

	function system.show_keyboard()
		if not love.keyboard.hasTextInput() then
			return love.keyboard.setTextInput( true )
		end
	end

	function system.hide_keyboard()
		return love.keyboard.setTextInput( false )
	end

	return util.protected_table( system )
end

return newSystemAPI
