
local plugin = require "src.plugin"
local event = require "src.event"
local editor = require "src.editor"
local res = require "src.resource"

res.register( "style", "light", "resources.styles.light" )
res.register( "style", "dark", "resources.styles.dark" )

res.register( "language", "plain text", "resources.languages.plain text" )
res.register( "language", "lua", "resources.languages.lua" )
res.register( "language", "flux", "resources.languages.flux" )

--[[
event.bind( "editor:key:ctrl-v", function()
	plugin.api.write( love.system.getClipboardText(), false )
	plugin.api.cursor_onscreen()
	editor.resetCursorBlink()
end )

event.bind( "editor:key:ctrl-c", function()
	love.system.setClipboardText( plugin.api.text() )
end )

event.bind( "editor:key:ctrl-x", function()
	love.system.setClipboardText( plugin.api.text() )
	plugin.api.write( "", false )
	editor.resetCursorBlink()
	plugin.api.cursor_onscreen()
end )
]]

local function wrapf_cursor( f, ... )
	local t = { ... }
	return function( v )
		f( v, unpack( t ) )
	end
end

event.bind( "editor:key:ctrl-c", function( editor )
	local t = {}
	editor.map_cursors( function( cursor )
		local text = editor.copy( cursor )
		t[#t + 1] = text
	end )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

event.bind( "editor:key:ctrl-shift-c", function( editor )
	local t = {}
	editor.map_cursors( function( cursor )
		local text = editor.copy( cursor, true )
		t[#t + 1] = text
	end )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

event.bind( "editor:key:ctrl-x", function( editor )
	local t = {}
	editor.map_cursors( function( cursor )
		local text = editor.copy( cursor )
		t[#t + 1] = text
	end )
		.map_cursors( editor.write, nil, "" )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

event.bind( "editor:key:ctrl-shift-x", function( editor )
	local t = {}
	editor.map_cursors( function( cursor )
		local text = editor.copy( cursor, true )
		t[#t + 1] = text
	end )
		.map_cursors( editor.write, nil, "" )
	love.system.setClipboardText( table.concat( t, "\n" ) )
end )

event.bind( "editor:key:ctrl-v", function( editor )
	editor.map_cursors( editor.write, nil, love.system.getClipboardText() )
end )

event.bind( "editor:key:ctrl-t", function( editor ) -- remove cursors from the end of a line
	editor.map_cursors( editor.cursor_remove, editor.filters.eofline ).resetCursorBlink()
end )

event.bind( "editor:key:ctrl-d", function( editor ) -- deselect all cursors
	editor.map_cursors( editor.deselect )
end )

event.bind( "editor:key:ctrl-l", function( editor ) -- select the line of each cursor
	editor.map_cursors( editor.select_line )
end )

event.bind( "editor:key:ctrl-a", function( editor ) -- select all text
	editor
		.map_cursors( editor.cursor_remove, editor.filters.count_start (editor.cursor_count() - 1) )
		.map_cursors( editor.cursor_home, nil, { full = true } )
		.map_cursors( editor.cursor_end, nil, { full = true, select = true } )
end )

event.bind( "editor:key:ctrl-s", function( editor )
	editor.map_cursors( editor.select_line )
end )

event.bind( "editor:key:kp7", function( editor )
	editor.map_cursors( editor.cursor_home, nil, { select = false, create = false, full = false } )
end )

event.bind( "editor:key:kp1", function( editor )
	editor.map_cursors( editor.cursor_end, nil, { select = false, create = false, full = false } )
end )

event.bind( "editor:key:shift-kp7", function( editor )
	editor.map_cursors( editor.cursor_home, nil, { select = true, create = false, full = false } )
end )

event.bind( "editor:key:shift-kp1", function( editor )
	editor.map_cursors( editor.cursor_end, nil, { select = true, create = false, full = false } )
end )

event.bind( "editor:key:ctrl-kp7", function( editor )
	editor.map_cursors( editor.cursor_home, nil, { select = false, create = false, full = true } )
end )

event.bind( "editor:key:ctrl-kp1", function( editor )
	editor.map_cursors( editor.cursor_end, nil, { select = false, create = false, full = true } )
end )

event.bind( "editor:key:ctrl-shift-kp7", function( editor )
	editor.map_cursors( editor.cursor_home, nil, { select = true, create = false, full = true } )
end )

event.bind( "editor:key:ctrl-shift-kp1", function( editor )
	editor.map_cursors( editor.cursor_end, nil, { select = true, create = false, full = true } )
end )

event.bind( "editor:key:up", function( editor )
	editor.map_cursors( editor.cursor_up, nil, { select = false, create = false } )
end )

event.bind( "editor:key:down", function( editor )
	editor.map_cursors( editor.cursor_down, nil, { select = false, create = false } )
end )

event.bind( "editor:key:alt-up", function( editor )
	editor.map_cursors( editor.cursor_up, nil, { select = false, create = true } )
end )

event.bind( "editor:key:alt-down", function( editor )
	editor.map_cursors( editor.cursor_down, nil, { select = false, create = true } )
end )

event.bind( "editor:key:shift-up", function( editor )
	editor.map_cursors( editor.cursor_up, nil, { select = true, create = false } )
end )

event.bind( "editor:key:shift-down", function( editor )
	editor.map_cursors( editor.cursor_down, nil, { select = true, create = false } )
end )

event.bind( "editor:key:left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = false, by_word = false, create = false } )
end )

event.bind( "editor:key:right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = false, by_word = false, create = false } )
end )

event.bind( "editor:key:alt-left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = false, by_word = false, create = true } )
end )

event.bind( "editor:key:alt-right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = false, by_word = false, create = true } )
end )

event.bind( "editor:key:ctrl-alt-left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = false, by_word = true, create = true } )
end )

event.bind( "editor:key:ctrl-alt-right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = false, by_word = true, create = true } )
end )

event.bind( "editor:key:shift-left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = true, by_word = false, create = false } )
end )

event.bind( "editor:key:shift-right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = true, by_word = false, create = false } )
end )

event.bind( "editor:key:ctrl-shift-left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = true, by_word = true, create = false } )
end )

event.bind( "editor:key:ctrl-shift-right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = true, by_word = true, create = false } )
end )

event.bind( "editor:key:ctrl-left", function( editor )
	editor.map_cursors( editor.cursor_left, nil, { select = false, by_word = true, create = false } )
end )

event.bind( "editor:key:ctrl-right", function( editor )
	editor.map_cursors( editor.cursor_right, nil, { select = false, by_word = true, create = false } )
end )

event.bind( "editor:key:delete", function( editor )
	editor.map_cursors( editor.delete )
end )

event.bind( "editor:key:backspace", function( editor )
	editor.map_cursors( editor.backspace )
end )

event.bind( "editor:key:tab", function( editor, text )
	editor.map_cursors( editor.write, nil, "\t" )
end )

event.bind( "editor:key:return", function( editor, text )
	editor.map_cursors( editor.write, nil, "\n" )
end )

event.bind( "editor:text", function( editor, text )
	editor.map_cursors( editor.write, nil, text )
end )
