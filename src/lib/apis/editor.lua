
local libtext_editor = require "src.lib.text_editor"
local libcursor = require "src.lib.cursor"
local libstyle = require "src.style"
local libresource = require "src.lib.resource"
local util = require "src.lib.util"
local libformatting = require "src.lib.formatting"

local function repositionEditor( editor, cursor )
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

local function newEditorAPI( editor )

	local api = {}
	local filters = {}
	local positions = {}

	local public = util.protected_table( api )

	api.filters = util.protected_table( filters )
	api.positions = util.protected_table( positions )

	local isMapping = false
	local shouldMerge = true

	local function tryMerge()
		if isMapping then
			shouldMerge = true
		else
			libcursor.merge( editor.cursors )
		end
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

	function api.copy( cursor, copyLine )
		if cursor.selection then
			local min, max = libcursor.order( cursor )

			if min[2] == max[2] then
				return editor.lines[min[2]]:sub( min[3], max[3] - 1 )
			else
				return editor.lines[min[2]]:sub( min[3] ) .. "\n" .. table.concat( editor.lines, "\n", min[2] + 1, max[2] - 1 ) .. (max[2] > min[1] + 1 and "\n" or "") .. editor.lines[max[2]]:sub( 1, max[3] - 1 )
			end
		elseif copyLine then
			return editor.lines[cursor.position[2]]
		end
	end

	function api.cursor_count()
		return #editor.cursors
	end

	function api.map( f, filter, ... )
		local t = {} -- libcursor.sort( editor.cursors )

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

	function api.new_cursor( position, ID )
		editor.cursors[#editor.cursors + 1] = libcursor.new()
		editor.cursors[#editor.cursors].position = position
		repositionEditor( editor, editor.cursors[#editor.cursors].position )
		tryMerge()

		return public
	end

	function api.set_cursor( position, ID )
		editor.cursors[1] = libcursor.new( ID )
		editor.cursors[1].position = position
		repositionEditor( editor, editor.cursors[1].position )

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

	function api.select_to( cursor, position )
		cursor.selection = cursor.selection or cursor.position
		cursor.position = position
		repositionEditor( editor, cursor.position )
		tryMerge()

		return public
	end

	function api.cursor_home( cursor, options )
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

	function filters.first()
		local i = 0
		return function()
			i = i + 1
			return i == 1
		end
	end

	function filters.last()
		local i = 0
		return function()
			i = i + 1
			return i == #editor.cursors
		end
	end

	function filters.eofline( cursor )
		return cursor.position[3] == #editor.lines[cursor.position[2]] + 1
	end

	function filters.sofline( cursor )
		return cursor.position[3] == 1
	end

	function filters.count_start( i )
			i = i or 1
		return function()
			i = i - 1
			return i >= 0
		end
	end

	function filters.count_end( i )
		i = #editor.cursors - (i or 1)
		return function()
			i = i - 1
			return i < 0
		end
	end

	filters.count = filters.count_start

	return public
end

return newEditorAPI
