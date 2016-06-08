
local event = require "src.event"
local plugin = require "src.plugin"

local light_theme = true
local language = 0

event.bind( "editor:key:ctrl-tab #style=light", function(editor)
	editor.setStyle "dark"
end )

event.bind( "editor:key:ctrl-tab #style=dark", function(editor)
	editor.setStyle "light"
end )

event.bind( "editor:key:ctrl-f #language=lua", function(editor)
	editor.setLanguage "plain text"
end )

event.bind( "editor:key:ctrl-f #language=flux", function(editor)
	editor.setLanguage "lua"
end )

event.bind( "editor:key:ctrl-f #language=plain text", function(editor)
	editor.setLanguage "flux"
end )
