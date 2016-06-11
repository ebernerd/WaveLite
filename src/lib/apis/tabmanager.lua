
local util = require "src.lib.util"
local editor = require "src.elements.CodeEditor"
local divisions = require "src.elements.Divisions"
local log = require "src.lib.log"

local function newTabManagerAPI(tabs)
	local tabmanager = require "src.elements.TabManager"

	local api = {}
	local public = util.protected_table(api)

	function api.open( tabtype, data, data2 )
		if tabtype == "file" then
			if type( data ) ~= "string" then return error( "expected string filename, got " .. type( data ) ) end

			return tabs:addEditor( editor( "file", data:gsub( "^.*/", "" ), love.filesystem.isFile( data ) and love.filesystem.read( data ) or "", data ) )

		elseif tabtype == "content" then
			if data and type( data ) ~= "string" then
				return error( "expected string content, got " .. type( data ) )
			end
			if data2 and type( data2 ) ~= "string" then
				return error( "expected string name, got " .. type( data2 ) )
			end

			return tabs:addEditor( editor( "content", data2, data ) )

		elseif tabtype == "log" then
			return tabs:addEditor( editor( "file", log.path:gsub( "^.*/", "" ), love.filesystem.isFile( log.path ) and love.filesystem.read( log.path ) or "", log.path ) )

		elseif tabtype == "canvas" then


		elseif tabtype == "console" then


		else
			return error( "unknown tab type '" .. tostring( tabtype ) .. "'" )

		end
	end

	function api.split_up( ... )
		local mode = "vertical"
		local p = tabs.parent
		local new = tabmanager()

		if p.direction == mode then
			p:add( new, tabs )

		else
			local div = divisions( mode )

			p:replaceChild( tabs, div )

			div:add( new )
			div:add( tabs )
		end
		
		return new.api
	end

	function api.split_down( ... )
		local mode = "vertical"
		local p = tabs.parent
		local new = tabmanager()

		if p.direction == mode then
			p:add( new, p:nextChild( tabs ) )

		else
			local div = divisions( mode )

			p:replaceChild( tabs, div )

			div:add( tabs )
			div:add( new )
		end
		
		return new.api
	end

	function api.split_left( ... )
		local mode = "horizontal"
		local p = tabs.parent
		local new = tabmanager()

		if p.direction == mode then
			p:add( new, tabs )

		else
			local div = divisions( mode )

			p:replaceChild( tabs, div )

			div:add( new )
			div:add( tabs )
		end
		
		return new.api
	end

	function api.split_right( ... )
		local mode = "horizontal"
		local p = tabs.parent
		local new = tabmanager()

		if p.direction == mode then
			p:add( new, p:nextChild( tabs ) )

		else
			local div = divisions( mode )

			p:replaceChild( tabs, div )

			div:add( tabs )
			div:add( new )
		end
		
		return new.api
	end

	function api.after( editor )
		for i = 1, #tabs.editors do
			if tabs.editors[i].api == editor then
				return tabs.editors[i == #tabs.editors and 1 or i + 1].api
			end
		end
	end

	function api.before( editor )
		for i = 1, #tabs.editors do
			if tabs.editors[i].api == editor then
				return tabs.editors[i == 1 and #tabs.editors or i - 1].api
			end
		end
	end

	return public

end

return newTabManagerAPI
