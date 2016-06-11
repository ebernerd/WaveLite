
local libtext_editor = require "src.lib.text_editor"
local libcursor = require "src.lib.cursor"
local libstyle = require "src.style"
local libresource = require "src.lib.resource"
local libevent = require "src.lib.event"
local util = require "src.lib.util"
local libformatting = require "src.lib.formatting"

local repositionEditor

local function newEditorAPI( editor )

	local api = {}
	local filters = {}
	local positions = {}
	local public = util.protected_table( api )
	local isMapping = false
	local shouldMerge = true
	local closing = false

	local function tryMerge()
		if isMapping then
			shouldMerge = true
		else
			libcursor.merge( editor.cursors )
		end
	end

	api.filters = util.protected_table( filters )
	api.positions = util.protected_table( positions )

	function api.refresh()
		if editor.path then
			editor.lines = util.splitlines( love.filesystem.isFile( editor.path ) and love.filesystem.read( editor.path ) or "" )
			libformatting.format( editor.lines, editor.formatting )

			for i = 1, #editor.cursors do
				if editor.cursors[i].position[2] > #editor.lines then
					editor.cursors[i].position[2] = #editor.lines
				end
				if editor.cursors[i].selection and editor.cursors[i].selection[2] > #editor.lines then
					editor.cursors[i].selection[2] = #editor.lines
				end
				if editor.cursors[i].position[3] > #editor.lines[editor.cursors[i].position[2]] then
					editor.cursors[i].position[3] = #editor.lines[editor.cursors[i].position[2]] + 1
				end
				if editor.cursors[i].selection and editor.cursors[i].selection[3] > #editor.lines[editor.cursors[i].selection[2]] then
					editor.cursors[i].selection[3] = #editor.lines[editor.cursors[i].selection[2]] + 1
				end
			end

			libcursor.merge( editor.cursors )
		end
	end

	function api.save()
		if editor.path then
			love.filesystem.write( editor.path, table.concat( editor.lines, "\n" ) )
			editor.opentime = os.time()
		end
	end

	function api.tabs()
		return editor.parent.api
	end

	function api.focus()
		editor.parent:switchTo( editor )

		return public
	end

	function api.close()
		closing = true
		libevent.invoke( "editor:close", editor )

		if closing then
			editor.parent:removeEditor( editor )
			closing = false
		end
	end

	function api.cancel_close()
		closing = false
	end

	function api.resetCursorBlink()
		editor.cursorblink = 0
		return public
	end

	function api.setLanguage( name )
		editor.langname = name
		editor.formatting.formatter = libresource.load( "language", name )
		libformatting.format( editor.lines, editor.formatting )

		return public
	end

	function api.language()
		return editor.langname
	end

	function api.setStyle( name )
		editor.stylename = name
		editor.style = libresource.load( "style", name )
		libformatting.format( editor.lines, editor.formatting )

		return public
	end

	function api.style()
		return editor.stylename
	end

	function api.title()
		return editor.title
	end

	function api.mode()
		return editor.mode
	end

	function api.setPath( path )
		editor.path = path
	end

	function api.path()
		return editor.path
	end

	function api.write( cursor, text )
		libtext_editor.write( editor.lines, editor.formatting, editor.cursors, cursor, text )
		editor.cursorblink = 0
		repositionEditor( editor, cursor.position )
		tryMerge()

		return public
	end

	function api.backspace( cursor )
		cursor.selection = cursor.selection or libcursor.left( editor.lines, cursor.position )
		api.write( cursor, "" )

		return public
	end

	function api.delete( cursor )
		cursor.selection = cursor.selection or libcursor.right( editor.lines, cursor.position )
		api.write( cursor, "" )

		return public
	end

	function api.read( cursor, copyLine )
		if cursor.selection then
			local min, max = libcursor.order( cursor )

			if min[2] == max[2] then
				return editor.lines[min[2]]:sub( min[3], max[3] - 1 )
			else
				return editor.lines[min[2]]:sub( min[3] )
					.. "\n"
					.. table.concat( editor.lines, "\n", min[2] + 1, max[2] - 1 )
					.. (max[2] > min[2] + 1 and "\n" or "")
					.. editor.lines[max[2]]:sub( 1, max[3] - 1 )
			end
		elseif copyLine then
			return editor.lines[cursor.position[2]]
		end
		return nil
	end

	function api.cursor_count()
		return #editor.cursors
	end

	function api.map( f, filter, ... )
		local t = {}

		for i = 1, #editor.cursors do
			t[i] = editor.cursors[i]
		end

		isMapping = true

		for i = 1, #t do
			if not filter or filter( t[i] ) then
				f( t[i], ... )
			end
		end

		if shouldMerge then
			libcursor.merge( editor.cursors )
		end

		isMapping = false

		return public
	end

	function api.robot( f, ... )
		local cursor = libcursor.new()
		return f and f( cursor, ... ) or cursor
	end

	function api.lines()
		return #editor.lines
	end

	function api.line( n )
		return editor.lines[n or 1]
	end

	function api.fline( n )
		return editor.formatting.lines[n or 1]
	end

	function api.new_cursor( position, ID )
		editor.cursors[#editor.cursors + 1] = libcursor.new( ID )
		editor.cursors[#editor.cursors].position = position or { 1, 1, 1, 1 }
		repositionEditor( editor, editor.cursors[#editor.cursors].position )
		tryMerge()

		return public
	end

	function api.set_cursor( position, ID )
		editor.cursors = { libcursor.new( ID ) }
		editor.cursors[1].position = position
		repositionEditor( editor, editor.cursors[1].position )

		return public
	end

	function api.goto_cursor_position( cursor, position )
		cursor.position = { position[1], position[2], position[3], position[4] }
		cursor.selection = false
		tryMerge()
	end

	function api.goto_char( cursor, char )
		cursor.selection = false
		cursor.position = { libcursor.toPosition( editor.lines, cursor.position[2], char ), cursor.position[2], math.min( char, #editor.lines[cursor.position[2]] + 1 ), char }
		tryMerge()
	end

	function api.goto_line( cursor, line )
		line = math.max( 1, math.min( line, #editor.lines ) )
		cursor.selection = false
		cursor.position = { libcursor.toPosition( editor.lines, line, cursor.position[3] ), line, cursor.position[3], cursor.position[4] }
		tryMerge()
	end

	function api.goto_position( cursor, position )
		local line, char
		local len = #editor.lines - 1

		for i = 1, #editor.lines do
			len = len + #editor.lines[i]
		end

		position = math.max( math.min( position, len ), 1 )
		line, char = libcursor.toLineChar( position )
		cursor.selection = false
		cursor.position = { position, line, char, char }
		tryMerge()
	end

	function api.select_to( cursor, position )
		cursor.selection = cursor.selection or cursor.position
		cursor.position = { position[1], position[2], position[3], position[4] }
		repositionEditor( editor, cursor.position )
		tryMerge()

		return public
	end

	function api.remove( cursor )
		for i = #editor.cursors, 1, -1 do
			if editor.cursors[i] == cursor then
				table.remove( editor.cursors, i )
			end
		end

		return public
	end

	function api.cursor_expand( cursor )
		local a, b = libcursor.order( cursor )
		cursor.selection = libcursor.expandleft( editor.lines, a )
		cursor.position = libcursor.expandright( editor.lines, b )
		
		tryMerge()
	end

	function api.cursor_home( cursor, options )
		options = options or {}

		if options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = { libcursor.toPosition( editor.lines, options.full and 1 or cursor.position[2], 1 ), options.full and 1 or cursor.position[2], 1, 1 }
			editor.cursorblink = 0
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = { libcursor.toPosition( editor.lines, options.full and 1 or cursor.position[2], 1 ), options.full and 1 or cursor.position[2], 1, 1 }
			cursor.selection = false
			editor.cursorblink = 0
		end

		repositionEditor( editor, cursor.position )
		tryMerge()

		return public
	end

	function api.cursor_end( cursor, options )
		options = options or {}

		if options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = { libcursor.toPosition( editor.lines, options.full and #editor.lines or cursor.position[2], math.huge ), options.full and #editor.lines or cursor.position[2], #editor.lines[options.full and #editor.lines or cursor.position[2]] + 1, math.huge }
			editor.cursorblink = 0
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = { libcursor.toPosition( editor.lines, options.full and #editor.lines or cursor.position[2], math.huge ), options.full and #editor.lines or cursor.position[2], #editor.lines[options.full and #editor.lines or cursor.position[2]] + 1, math.huge }
			cursor.selection = false
			editor.cursorblink = 0
		end

		repositionEditor( editor, cursor.position )
		tryMerge()

		return public
	end

	function api.cursor_up( cursor, options )
		options = options or {}

		local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor.up( editor.lines, tabWidth, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor.up( editor.lines, tabWidth, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor.up( editor.lines, tabWidth, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return public
	end

	function api.cursor_down( cursor, options )
		options = options or {}

		local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" )
		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor.down( editor.lines, tabWidth, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor.down( editor.lines, tabWidth, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor.down( editor.lines, tabWidth, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return public
	end

	function api.cursor_left( cursor, options )
		options = options or {}

		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.smaller( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "leftword" or "left"]( editor.lines, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return public
	end

	function api.cursor_right( cursor, options )
		options = options or {}

		if options.create then
			local c = libcursor.new( options.ID )
			c.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
			editor.cursors[#editor.cursors + 1] = c
			repositionEditor( editor, c.position )
		elseif options.select then
			cursor.selection = cursor.selection or cursor.position
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		elseif cursor.selection then
			cursor.position = libcursor.larger( cursor.position, cursor.selection )
			cursor.selection = false
		else
			cursor.position = libcursor[options.by_word and "rightword" or "right"]( editor.lines, cursor.position )
		end

		repositionEditor( editor, cursor.position )
		tryMerge()
		editor.cursorblink = 0

		return public
	end

	function api.deselect( cursor )
		cursor.selection = false
	end

	function api.select_line( cursor )
		local min, max = libcursor.order( cursor )

		cursor.selection = { libcursor.toPosition( editor.lines, min[2], 1 ), min[2], 1, 1 }
		cursor.position = { libcursor.toPosition( editor.lines, max[2], #editor.lines[max[2]] + 1 ), max[2], #editor.lines[max[2]] + 1, #editor.lines[max[2]] + 1 }

		-- repositionEditor( editor, cursor.position ) ?

		tryMerge()

		return public
	end

	function api.show( position )
		repositionEditor( editor, position )

		return public
	end

	function filters.first( n )
		local i = 0
		n = n or 1
		return function()
			i = i + 1
			return i <= n
		end
	end

	function filters.last( n )
		local i = 0
		n = n or 1
		return function()
			i = i + 1
			return i > #editor.cursors - n
		end
	end

	function filters.only( n )
		local i = 0
		n = n or 1
		return function()
			i = i + 1
			return i == n
		end
	end

	function filters.except( n )
		local i = 0
		n = n or 1
		return function()
			i = i + 1
			return i ~= n
		end
	end

	function filters.eofline( cursor )
		return cursor.position[3] == #editor.lines[cursor.position[2]] + 1
	end

	function filters.sofline( cursor )
		return cursor.position[3] == 1
	end

	function filters.has_selection()
		return function( cursor )
			return cursor.selection ~= false
		end
	end

	function filters.negate( f )
		return function( ... )
			return not f( ... )
		end
	end

	function filters.union( ... )
		local t = { ... }
		return #t == 1 and t[1] or #t == 2 and function( ... ) return t[1]( ... ) or t[2]( ... ) end or function( ... )
			for i = 1, #t do
				if t[i]( ... ) then
					return true
				end
			end
			return false
		end
	end

	function filters.intersection( ... )
		local t = { ... }
		return #t == 1 and t[1] or #t == 2 and function( ... ) return t[1]( ... ) and t[2]( ... ) end or function( ... )
			for i = 1, #t do
				if not t[i]( ... ) then
					return false
				end
			end
			return true
		end
	end

	filters.count = filters.count_start

	return public
end

function repositionEditor( editor, cursor )
	local line = cursor[2]
	local char = cursor[3]
	local font = libstyle.get( editor.style, "editor:Font" )
	local fHeight = font:getHeight()
	local space = font:getWidth " "
	local tabWidth = libstyle.get( editor.style, "editor:Tabs.Width" ) * space

	local yTop = fHeight * math.max( 0, line - 2 )
	local yBottom = fHeight * math.min( #editor.lines, line + 1 )
	local xLeft = util.lineWidthUpTo( editor.lines[line], math.max( 1, char - 1 ), font, tabWidth )
	local xRight = util.lineWidthUpTo( editor.lines[line], char, font, tabWidth ) + space + space

	if yBottom - editor.scrollY > editor.viewHeight then
		editor.scrollY = yBottom - editor.viewHeight
	end
	if yTop - editor.scrollY < 0 then
		editor.scrollY = yTop
	end

	if xRight - editor.scrollX > editor.viewWidth then
		editor.scrollX = xRight - editor.viewWidth
	end

	if xLeft - editor.scrollX < 0 then
		editor.scrollX = xLeft
	end
end

return newEditorAPI