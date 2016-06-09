
local event = require "src.lib.event"
local res = require "src.lib.resource"

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

event.bind( "editor:key:ctrl-i", function( editor )

	editor.map( function( c ) -- map through all cursors
		editor.robot( function( cursor ) -- create a robot for each one
			editor.move_cursor( cursor, c.position ) -- move it to the target cursor
			editor.cursor_home( cursor, {} ) -- go to the start of the line
			editor.write( cursor, "\t" ) -- write a tab
		end )
	end )

end )

event.bind( "editor:key:ctrl-shift-i", function(editor)

	editor.map( function( c )
		editor.robot( function(cursor)
			editor.move_cursor( cursor, c.position )
			editor.cursor_home( cursor, {} )

			if editor.read( cursor, true ):sub( 1, 1 ) == "\t" then
				editor.delete( cursor )
			end
		end )
	end )

end )
