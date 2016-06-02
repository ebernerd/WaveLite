
local event = require "src.event"
local plugin = require "src.plugin"
local editor = require "src.editor"

local light_theme = true
local language = 0

event.bind( "editor:key:ctrl-tab", function()
	light_theme = not light_theme
	editor.tab().style = require( light_theme and "resources.styles.light" or "resources.styles.dark" )
	require "src.formatting" .format( editor.tab().lines, editor.tab().formatting )
end )

event.bind( "editor:key:ctrl-f", function()
	language = (language + 1) % 3
	editor.tab().formatting.formatter = require( language == 0 and "resources.languages.lua" or language == 1 and "resources.languages.plain text" or language == 2 and "resources.languages.flux" )
	require "src.formatting" .format( editor.tab().lines, editor.tab().formatting )
end )
