
local light_theme = true
local language = 0

WaveLite.event.bind( "editor:key:ctrl-tab #style=core:light", function(editor)
	editor.setStyle "core:dark"
end )

WaveLite.event.bind( "editor:key:ctrl-tab #style=core:dark", function(editor)
	editor.setStyle "core:light"
end )

WaveLite.event.bind( "editor:key:ctrl-f #language=core:lua", function(editor)
	editor.setLanguage "core:plain text"
end )

WaveLite.event.bind( "editor:key:ctrl-f #language=core:flux", function(editor)
	editor.setLanguage "core:lua"
end )

WaveLite.event.bind( "editor:key:ctrl-f #language=core:plain text", function(editor)
	editor.setLanguage "core:flux"
end )

WaveLite.event.bind( "editor:key:ctrl-i", function( editor )

	editor.map( function( c ) -- map through all cursors
		editor.robot( function( cursor ) -- create a robot for each one
			editor.goto_cursor_position( cursor, c.position ) -- move it to the target cursor
			editor.cursor_home( cursor, {} ) -- go to the start of the line
			editor.write( cursor, "\t" ) -- write a tab
		end )
	end )

end )

WaveLite.event.bind( "editor:key:ctrl-shift-i", function(editor)

	editor.map( function( c )
		editor.robot( function(cursor)
			editor.goto_cursor_position( cursor, c.position )
			editor.cursor_home( cursor, {} )

			if editor.read( cursor, true ):sub( 1, 1 ) == "\t" then
				editor.delete( cursor )
			end
		end )
	end )

end )

WaveLite.event.bind( "editor:key:ctrl-t", function(editor)
	local title = ""
	local content = {}
	local i = 0

	editor.map( function( cursor )
		local text = editor.read( cursor )

		i = i + 1

		if i == 1 then
			title = text
		else
			content[#content + 1] = text
		end
	end )

	local new_editor = editor.tabs().open( "content", table.concat( content, "\n" ), title )

	new_editor.focus()
	new_editor.setLanguage( editor.language() )
end )

WaveLite.event.bind( "editor:key:ctrl-w", function(editor)
	editor.close()
end )
