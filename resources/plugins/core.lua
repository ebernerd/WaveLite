
WaveLite.resource.register( "style", "light", "resources.styles.light" )
WaveLite.resource.register( "style", "dark", "resources.styles.dark" )

WaveLite.resource.register( "language", "plain text", "resources.languages.plain text" )
WaveLite.resource.register( "language", "lua", "resources.languages.lua" )
WaveLite.resource.register( "language", "flux", "resources.languages.flux" )

WaveLite.event.bind( "editor:touch", function(editor, position)
	if position[4] == 0 then
		editor.set_cursor( position ).map( editor.select_line )
	else
		editor.set_cursor( position )
	end
end )

WaveLite.event.bind( "editor:ctrl-touch", function(editor, position)
	if position[4] == 0 then
		editor.new_cursor( position ).map( editor.select_line )
	else
		editor.new_cursor( position )
	end
end )

WaveLite.event.bind( "editor:shift-touch", function(editor, position)
	editor.map( editor.select_to, editor.filters.last(), position )
end )

WaveLite.event.bind( "editor:move", function(editor, position)
	editor.map( editor.select_to, editor.filters.last(), position )
end )

WaveLite.event.bind( "editor:key:ctrl-c", function( editor )
	local t = {}
	editor.map( function( cursor )
		local text = editor.read( cursor )
		t[#t + 1] = text
	end )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-c", function( editor )
	local t = {}
	editor.map( function( cursor )
		local text = editor.read( cursor, true )
		t[#t + 1] = text
	end )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

WaveLite.event.bind( "editor:key:ctrl-x", function( editor )
	local t = {}
	editor.map( function( cursor )
		local text = editor.read( cursor )
		t[#t + 1] = text
	end )
		.map( editor.write, nil, "" )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-x", function( editor )
	local t = {}
	editor.map( function( cursor )
		local text = editor.read( cursor, true )
		t[#t + 1] = text
	end )
		.map( editor.write, nil, "" )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

WaveLite.event.bind( "editor:key:ctrl-v", function( editor )
	editor.map( editor.write, nil, love.system.getClipboardText() )
end )

WaveLite.event.bind( "editor:key:ctrl-t", function( editor ) -- remove cursors from the end of a line
	editor.map( editor.remove_cursor, editor.filters.eofline ).resetCursorBlink()
end )

WaveLite.event.bind( "editor:key:ctrl-d", function( editor ) -- deselect all cursors
	editor.map( editor.deselect )
end )

WaveLite.event.bind( "editor:key:ctrl-l", function( editor ) -- select the line of each cursor
	editor.map( editor.select_line )
end )

WaveLite.event.bind( "editor:key:ctrl-a", function( editor ) -- select all text
	editor
		.map( editor.remove, editor.filters.negate( editor.filters.first() ) )
		.map( editor.cursor_home, nil, { full = true } )
		.map( editor.cursor_end, nil, { full = true, select = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-s", function( editor )
	editor.map( editor.select_line )
end )

WaveLite.event.bind( "editor:key:kp7", function( editor )
	editor.map( editor.cursor_home, nil, { select = false, create = false, full = false } )
end )

WaveLite.event.bind( "editor:key:kp1", function( editor )
	editor.map( editor.cursor_end, nil, { select = false, create = false, full = false } )
end )

WaveLite.event.bind( "editor:key:shift-kp7", function( editor )
	editor.map( editor.cursor_home, nil, { select = true, create = false, full = false } )
end )

WaveLite.event.bind( "editor:key:shift-kp1", function( editor )
	editor.map( editor.cursor_end, nil, { select = true, create = false, full = false } )
end )

WaveLite.event.bind( "editor:key:ctrl-kp7", function( editor )
	editor.map( editor.cursor_home, nil, { select = false, create = false, full = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-kp1", function( editor )
	editor.map( editor.cursor_end, nil, { select = false, create = false, full = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-kp7", function( editor )
	editor.map( editor.cursor_home, nil, { select = true, create = false, full = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-kp1", function( editor )
	editor.map( editor.cursor_end, nil, { select = true, create = false, full = true } )
end )

WaveLite.event.bind( "editor:key:up", function( editor )
	editor.map( editor.cursor_up, nil, { select = false, create = false } )
end )

WaveLite.event.bind( "editor:key:down", function( editor )
	editor.map( editor.cursor_down, nil, { select = false, create = false } )
end )

WaveLite.event.bind( "editor:key:alt-up", function( editor )
	editor.map( editor.cursor_up, nil, { select = false, create = true } )
end )

WaveLite.event.bind( "editor:key:alt-down", function( editor )
	editor.map( editor.cursor_down, nil, { select = false, create = true } )
end )

WaveLite.event.bind( "editor:key:shift-up", function( editor )
	editor.map( editor.cursor_up, nil, { select = true, create = false } )
end )

WaveLite.event.bind( "editor:key:shift-down", function( editor )
	editor.map( editor.cursor_down, nil, { select = true, create = false } )
end )

WaveLite.event.bind( "editor:key:left", function( editor )
	editor.map( editor.cursor_left, nil, { select = false, by_word = false, create = false } )
end )

WaveLite.event.bind( "editor:key:right", function( editor )
	editor.map( editor.cursor_right, nil, { select = false, by_word = false, create = false } )
end )

WaveLite.event.bind( "editor:key:alt-left", function( editor )
	editor.map( editor.cursor_left, nil, { select = false, by_word = false, create = true } )
end )

WaveLite.event.bind( "editor:key:alt-right", function( editor )
	editor.map( editor.cursor_right, nil, { select = false, by_word = false, create = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-left", function( editor )
	editor.map( editor.cursor_left, nil, { select = false, by_word = true, create = true } )
end )

WaveLite.event.bind( "editor:key:ctrl-alt-right", function( editor )
	editor.map( editor.cursor_right, nil, { select = false, by_word = true, create = true } )
end )

WaveLite.event.bind( "editor:key:shift-left", function( editor )
	editor.map( editor.cursor_left, nil, { select = true, by_word = false, create = false } )
end )

WaveLite.event.bind( "editor:key:shift-right", function( editor )
	editor.map( editor.cursor_right, nil, { select = true, by_word = false, create = false } )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-left", function( editor )
	editor.map( editor.cursor_left, nil, { select = true, by_word = true, create = false } )
end )

WaveLite.event.bind( "editor:key:ctrl-shift-right", function( editor )
	editor.map( editor.cursor_right, nil, { select = true, by_word = true, create = false } )
end )

WaveLite.event.bind( "editor:key:ctrl-left", function( editor )
	editor.map( editor.cursor_left, nil, { select = false, by_word = true, create = false } )
end )

WaveLite.event.bind( "editor:key:ctrl-right", function( editor )
	editor.map( editor.cursor_right, nil, { select = false, by_word = true, create = false } )
end )

WaveLite.event.bind( "editor:key:delete", function( editor )
	editor.map( editor.delete )
end )

WaveLite.event.bind( "editor:key:backspace", function( editor )
	editor.map( editor.backspace )
end )

WaveLite.event.bind( "editor:key:tab", function( editor, text )
	editor.map( editor.write, nil, "\t" )
end )

WaveLite.event.bind( "editor:key:return", function( editor, text )
	editor.map( editor.write, nil, "\n" )
end )

WaveLite.event.bind( "editor:text", function( editor, text )
	editor.map( editor.write, nil, text )
end )
