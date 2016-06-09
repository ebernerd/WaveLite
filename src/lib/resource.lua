
local libformatting = require "src.lib.formatting"
local libstyle = require "src.style"

local loaders = {}
local res = {}

function loaders.text( value, name )
	return value
end

function loaders.language( value, name )
	value = type( value ) == "string" and require( value ) or value
	return type( value ) == "table" and libformatting.newFormatter( value ) or type( value ) == "function" and value or nil
end

function loaders.style( value, name )
	value = type( value ) == "string" and require( value ) or value
	return type( value ) == "table" and libstyle.new( value ) or nil
end

local resource = {}

function resource.register( type, name, value )
	res[type] = res[type] or {}

	if loaders[type] then
		res[type][name] = loaders[type]( value, name )
	else
		res[type][name] = value
	end
end

function resource.unregister( type, name, value )
	(res[type] or {})[name] = nil
end

function resource.load( type, name )
	return (res[type] or {})[name]
end

return resource
