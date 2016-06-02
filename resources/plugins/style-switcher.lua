
local event = require "src.event"
local plugin = require "src.plugin"
local editor = require "src.editor"

local light_theme = true

event.bind( "editor:key:ctrl-tab", function()
	light_theme = not light_theme
	editor.tab().style = require( light_theme and "resources.styles.light" or "resources.styles.dark" )
	require "src.formatting" .format( editor.tab().lines, editor.tab().formatting )
end )
