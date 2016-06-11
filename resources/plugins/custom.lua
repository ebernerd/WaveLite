
WaveLite.event.bind( "editor:key:ctrl-kp8", function( editor ) -- remove cursors from the end of a line
	editor.tabs().split_up().open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp2", function( editor ) -- remove cursors from the end of a line
	editor.tabs().split_down().open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp4", function( editor ) -- remove cursors from the end of a line
	editor.tabs().split_left().open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp6", function( editor ) -- remove cursors from the end of a line
	editor.tabs().split_right().open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-r", function( editor ) -- remove cursors from the end of a line
	editor.map( editor.remove, editor.filters.eofline ).resetCursorBlink()
end )

WaveLite.event.bind( "editor:key:ctrl-d", function( editor ) -- deselect all cursors
	editor.map( editor.deselect )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-l", function( editor ) -- select the line of each cursor
	editor.map( editor.select_line )
end )

WaveLite.event.bind( "editor:key:alt-s #style=core:light", function(editor)
	editor.setStyle "core:dark"
end )

WaveLite.event.bind( "editor:key:alt-s #style=core:dark", function(editor)
	editor.setStyle "core:light"
end )

WaveLite.event.bind( "editor:key:ctrl-l #language=core:lua", function(editor)
	editor.setLanguage "core:plain text"
end )

WaveLite.event.bind( "editor:key:ctrl-l #language=core:flux", function(editor)
	editor.setLanguage "core:lua"
end )

WaveLite.event.bind( "editor:key:ctrl-l #language=core:plain text", function(editor)
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
	local title = "untitled"
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
