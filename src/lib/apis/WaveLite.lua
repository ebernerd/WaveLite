
local WaveLite = require "src.WaveLite"
local util = require "src.lib.util"
local resource = require "src.lib.resource"
local event = require "src.lib.event"
local CodeEditor = require "src.elements.CodeEditor"
local TabManager = require "src.elements.TabManager"

--[[
	WaveLite.*
		event
			void bind(string event, function callback)
			void unbind(string event, function callback)
			void invoke(string event, ...)
				potential bugs and stuff if invoking events with bad parameters?
				maybe make this fire a "<plugin name>:event" event instead?
		editor
			editor open(string type, options {dependent on type})
			bool close(editor)

		resource
			void register(string type, string name, data)

]]

return function( plugin_name )
	local api = {}

	api.event = {}
	api.editor = {}
	api.resource = {}

	function api.event.bind( ename, callback )
		if type(    ename ) ~=   "string" then return error( "expected string event-name, got " .. type(    ename ) ) end
		if type( callback ) ~= "function" then return error( "expected function callback, got " .. type( callback ) ) end

		return event.bind( ename, callback, plugin_name )
	end

	function api.event.unbind( ename, callback )
		if type(    ename ) ~=   "string" then return error( "expected string event-name, got " .. type(    ename ) ) end
		if type( callback ) ~= "function" then return error( "expected function callback, got " .. type( callback ) ) end

		return event.unbind( ename, callback, plugin_name )
	end

	function api.event.invoke( ename, ... )
		if type( ename ) ~= "string" then return error( "expected string event-name, got " .. type( ename ) ) end

		return event.unbind( plugin_name .. ":" .. ename, ... )
	end

	function api.resource.register( rtype, name, data )
		if type( rtype ) ~= "string" then return error( "expected string type, got " .. type( rtype ) ) end
		if type(  name ) ~= "string" then return error( "expected string name, got " .. type(  name ) ) end

		return resource.register( rtype, plugin_name .. ":" .. name, data )
	end

	function api.resource.unregister( rtype, name )
		if type( rtype ) ~= "string" then return error( "expected string type, got " .. type( rtype ) ) end
		if type(  name ) ~= "string" then return error( "expected string name, got " .. type(  name ) ) end

		return resource.unregister( rtype, plugin_name .. ":" .. name )
	end

	function api.resource.load( rtype, name )
		if type( rtype ) ~= "string" then return error( "expected string type, got " .. type( rtype ) ) end
		if type(  name ) ~= "string" then return error( "expected string name, got " .. type(  name ) ) end

		return resource.load( rtype, name )
	end

	function api.split_editor( editor, dir, ... )
		for i = 1, #WaveLite.editors do
			if WaveLite.editors[i].api == editor then
				return WaveLite.splitEditor( WaveLite.editors[i], CodeEditor( ... ), dir ).api
			end
		end
	end

	function api.split_tabs( tabs, dir, ... )
		for i = 1, #WaveLite.tab_managers do
			if WaveLite.tab_managers[i].api == tabs then
				return WaveLite.splitTab( WaveLite.tab_managers[i], TabManager(), dir ).api
			end
		end
	end

	function api.close_editor( editor )
		for i = 1, #WaveLite.editors do
			if WaveLite.editors[i].api == editor then
				return WaveLite.closeEditor( WaveLite.editors[i] )
			end
		end
	end

	function api.close_tab( tabs )
		for i = 1, #WaveLite.tab_managers do
			if WaveLite.tab_managers[i].api == tabs then
				return WaveLite.closeTab( WaveLite.tab_managers[i] )
			end
		end
	end

	return util.protected_table( api )
end
