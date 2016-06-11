
WaveLite.event.bind( "editor:key:ctrl-w", function( editor )
	WaveLite.close_editor( editor )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-kp6", function( editor )
	WaveLite.split_editor( editor, "right", "content" )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-kp4", function( editor )
	WaveLite.split_editor( editor, "left", "content" )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-kp8", function( editor )
	WaveLite.split_editor( editor, "up", "content" )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-kp2", function( editor )
	WaveLite.split_editor( editor, "down", "content" )
end )

WaveLite.event.bind( "editor:alt-touch", function( editor, position )
	if position[2] == 4 and editor.line(4) == "\tClick on this line to copy the path to your clipboard and open it" then
		local name = editor.line(3):match "^\tWrite your computer username between the '<' and '>' <(.-)>$"

		if name then
			local path = "C:\\Users\\" .. name .. "\\Appdata\\Roaming\\LOVE\\WaveLite"
			if system.open_url( path ) then
				system.copy( path )
			else
				local char = 56
				editor.set_cursor( { position[1] + char - position[3], position[2], char, char } )
				editor.map( editor.goto_line, nil, position[2] - 1 )
				
				for i = 1, #name do
					editor.map( editor.cursor_right, nil, { select = true } )
				end
			end
		end
	end
end )

WaveLite.event.bind( "editor:alt-touch", function( editor, position )
	local line = editor.line( position[2] ) or ""

	if line:find "%s*open%s+'.-'%s*$" then
		editor.tabs().open( "file", line:match "%s*open%s+'(.-)'%s*$" ).focus().setLanguage( editor.language() ).setStyle( editor.style() )
	elseif line:find "%s*open%s+'.-'%s*%[.-%]%s*$" then
		editor.tabs().open( "file", line:match "%s*open%s+'(.-)'%s*%[.-%]%s*$" ).focus().setLanguage( line:match "%s*open%s+'.-'%s*%[(.-)%]%s*$" ).setStyle( editor.style() )
	end
end )

WaveLite.event.bind( "editor:key:ctrl-kp8", function( editor ) -- remove cursors from the end of a line
	WaveLite.split_tabs( editor.tabs(), "up" ).open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp2", function( editor ) -- remove cursors from the end of a line
	WaveLite.split_tabs( editor.tabs(), "down" ).open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp4", function( editor ) -- remove cursors from the end of a line
	WaveLite.split_tabs( editor.tabs(), "left" ).open "content" .focus()
end )

WaveLite.event.bind( "editor:key:ctrl-kp6", function( editor ) -- remove cursors from the end of a line
	WaveLite.split_tabs( editor.tabs(), "right" ).open "content" .focus()
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

WaveLite.event.bind( "editor:key:ctrl-shift-t", function(editor)
	local file

	editor.map( function( cursor )
		file = editor.read( cursor, true )
	end, editor.filters.first() )

	local new_editor = editor.tabs().open( "file", file )

	new_editor.focus()
	new_editor.setLanguage( editor.language() )
	new_editor.setStyle( editor.style() )
end )

WaveLite.event.bind( "editor:key:ctrl-w", function(editor)
	-- editor.close()
end )

WaveLite.event.bind( "editor:key:alt-shift-s", function( editor )
	editor.map( editor.select_line )
end )
