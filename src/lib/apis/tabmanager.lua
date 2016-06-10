
local util = require "src.lib.util"
local editor = require "src.elements.CodeEditor"

local function newTabManagerAPI(tabs)

	local api = {}
	local public = util.protected_table(api)

	function api.open( tabtype, data, data2 )
		if tabtype == "blank" then
			if data and type( data ) ~= "string" then
				return error( "expected string content, got " .. type( data ) )
			end

			return tabs:addEditor( editor( data ) )

		elseif tabtype == "file" then
			if type( data ) ~= "string" then
				return error( "expected string filename, got " .. type( data ) )
			end

			if not love.filesystem.exists( data ) then
				return false, "no such file '" .. data .. "'"
			end

			return tabs:addEditor( editor( data:gsub( "^.*/", "" ), love.filesystem.read( data ) ) )

		elseif tabtype == "content" then
			if type( data ) ~= "string" then
				return error( "expected string content, got " .. type( data ) )
			end
			if data2 and type( data2 ) ~= "string" then
				return error( "expected string name, got " .. type( data2 ) )
			end

			return tabs:addEditor( editor( data2, data ) )

		end
	end

	return public

end

return newTabManagerAPI
