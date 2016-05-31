
local START_TEXT_LOOK_AT_START_OF_FILE = [==[
-- Aha, I see you're looking at this?

print "I changed the syntax highlighting style"

if style.better() then
	print 'Great!'
else
	print [=[ I'm so sorry ]]: ]=]
end

--[=[
	now for some [[nested]] comments
	yeah they work fine
]=]

print( 5 > 2 and true or false )
]==]

local function rgb( n )
	return { math.floor( n / 256 ^ 2 ) % 256, math.floor( n / 256 ) % 256, n % 256 }
end

local themes = {
	Default = {
		Keyword = {
			Loop = {
				_Default = rgb( 0xc53d67 );
			};
			Function = {
				_Default = rgb( 0xc53d67 );
			};
			Declare = {
				_Default = rgb( 0xc53d67 );
			};
			Control = {
				_Default = rgb( 0xc53d67 );
			};
			_Default = rgb( 0xc53d67 );
		},
		Operator = {
			_Default = { 121, 250, 70 };
		},
		Constant = {
			_Default = { 40, 40, 40 };
			Identifier = rgb( 0x404040 );
			Boolean = rgb( 0xed912c );
			Number = rgb( 0x3092c6 );
			String = rgb( 0x3092c6 );
		},
		Operator = {
			_Default = rgb( 0xc53d67 );
		};
		Symbol = {
			_Default = rgb( 0xc53d67 );
		},
		Comment = {
			_Default = rgb( 0x919d9f );
		},

		_Default = rgb( 0x404040 ),
		_Background = rgb( 0xfafafa );
	}
}

local languages = {
	lua = {
		keywords = {
			["if"] = "Keyword.Control.If";
			["else"] = "Keyword.Control.Else";
			["elseif"] = "Keyword.Control.Elseif";

			["repeat"] = "Keyword.Loop.Repeat";
			["while"] = "Keyword.Loop.While";

			["for"] = "Keyword.Loop.For";
			["in"] = "Keyword";

			["and"] = "Operator.And";
			["or"] = "Operator.Or";
			["not"] = "Operator.Not";

			["break"] = "Keyword.Control.Break";
			["return"] = "Keyword.Control.Return";

			["do"] = "Keyword";
			["then"] = "Keyword";
			["until"] = "Keyword";
			["end"] = "Keyword.Control";

			["function"] = "Keyword.Function";

			["local"] = "Keyword.Declare";

			["true"] = "Constant.Boolean";
			["false"] = "Constant.Boolean";
			["nil"] = "Constant.Null";
		};

		symbols = {
			["="] = "Symbol";

			["["] = "Symbol.Bracket.Square";
			["]"] = "Symbol.Bracket.Square";
			["("] = "Symbol.Bracket.Round";
			[")"] = "Symbol.Bracket.Round";
			["{"] = "Symbol.Bracket.Curly";
			["}"] = "Symbol.Bracket.Curly";

			["+"] = "Operator.Math.Add";
			["-"] = "Operator.Math.Sub";
			["*"] = "Operator.Math.Mul";
			["/"] = "Operator.Math.Div";
			["%"] = "Operator.Math.Mod";
			["^"] = "Operator.Math.Pow";

			["=="] = "Operator.Compare.Eq";
			["~="] = "Operator.Compare.Neq";
			[">="] = "Operator.Compare.Gte";
			["<="] = "Operator.Compare.Lte";
			[">"] = "Operator.Compare.Gt";
			["<"] = "Operator.Compare.Lt";

			["#"] = "Operator.Len";

			["."] = "Symbol.Index";
			[":"] = "Symbol.Index";

			[","] = "Symbol.Sep";
			[";"] = "Symbol.Sep";
		};

		comments = {
			start = {
				line = "%-%-";
				multiline = "%-%-%[(=*)%[";
			};
			finish = {
				line = "$";
				multiline = "%]%1%]";
			};
		};

		strings = {
			start = {
				line = "[\"\']";
				multiline = "%[(=*)%[";
			};
			finish = {
				line = "%1";
				multiline = "%]%1%]";
			};
			escape = {
				line = "\\";
				multiline = nil;
			};
		};
	}
}

local function copyt( t )
	local t2 = {}
	for k, v in pairs( t ) do
		t2[k] = type(v) == "table" and copyt(v) or v
	end
	return t2
end

local function comparet( a, b )
	for k, v in pairs( a ) do
		if b[k] ~= v then return true end
	end
	for k, v in pairs( b ) do
		if a[k] ~= v then return true end
	end
end

local function findEndingMatch( text, initial, final, escape, position )
	if not final then error("hey", 2)end
	local escaped = false
	local close = "^" .. initial:gsub( "^(.*)$", final )
	local esc = escape and "^" .. initial:gsub( "^(.*)$", escape )

	while position <= #text + 1 do
		if escaped then
			escaped = false
		elseif escape and text:find( esc, position ) then
			position = select( 2, text:find( esc, position ) )
			escaped = true
		else
			local s, f = text:find( close, position )
			if s then
				return f
			end
		end

		position = position + 1
	end
end

local function longestOf( text, position, a, b, c, d, A, B, C, D )
	local t = {
		{ a, text:match( "^" .. a:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ b, text:match( "^" .. b:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ c, text:match( "^" .. c:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
		{ d, text:match( "^" .. d:gsub( "%(", "" ):gsub( "%)", "" ), position ) };
	}
	local l = -1
	local n = 0

	for i = 1, #t do
		if t[i][2] and #t[i][2] > l then
			n = i
		end
	end

	return n > 0 and text:match( "^" .. t[n][1], position ), n > 0 and ({A, B, C, D})[n]
end

local function formatText( text )
	return text:gsub( "\\", "\\\\" ):gsub( "{", "\\{" )
end

local function lookupIndexInStyle(index, style)
	for part in index:gmatch "[^%.]+" do
		style = style[part] or style._Default or style
	end
	return style._Default or style
end

local function newTextBody(text)

	local t = {}
	local lines = { "" }

	for i = 1, #text do
		if text:sub( i, i ) == "\n" then
			lines[#lines + 1] = ""
		else
			lines[#lines] = lines[#lines] .. text:sub( i, i )
		end
	end

	t.state = {}
	t.lines = lines
	t.fmtlines = {}
	t.states = setmetatable( { [0] = t.state }, { __index = function(t, i) return t[i-1] end } )

	function t:format( i, upper )
		upper = upper or i or #self.lines
		i = i or 1

		while i <= upper and i <= #self.lines do

			local state = copyt( self.states[i - 1] ) -- this is for keeping track of things like (isInClass) to highlight keywords like 'super', 'private', etc
			self.fmtlines[i] = self:formatLine( state, self.lines[i] )

			if i == upper and comparet( state, self.states[i] ) then -- if the line caused the next to have a changed state
				upper = upper + 1
			end

			self.states[i] = state
			i = i + 1

		end
	end

	function t:insert( n, line )
		table.insert( self.lines, n, line )
		table.insert( self.fmtlines, n, "" )
		table.insert( self.states, n, {} )

		return self:format( n )
	end

	function t:remove( n )
		table.remove( self.lines, n )
		table.remove( self.fmtlines, n )
		table.remove( self.states, n )

		return self:format( n )
	end

	function t:set( n, line )
		self.lines[n] = line

		return self:format( n )
	end

	function t:get( n )
		return self.lines[n]
	end

	function t:getFormatted( n )
		return self.fmtlines[n]
	end

	function t:formatLine( state, line )
		return formatText( line ) -- with fancy text formatting
	end

	return t

end

local function createLanguageFormatter(lang)
	return function(state, line)

		local i = 1
		local res = ""

		if state.in_section then
			local index = state.in_section:match "_(.+)"
			local sindex = (state.in_section == "comment_line" or state.in_section == "comment_multiline") and "comments" or "strings"
			local ending = findEndingMatch( line, state.string_match, lang[sindex].finish[index], lang[sindex].escape and lang[sindex].escape[index], 1 )

			if ending then
				state.in_section = false
				i = ending + 1
				res = (sindex == "strings" and "{Constant.String:" or "{Comment:") .. formatText( line:sub( 1, ending ) ) .. "}"
			else
				return (sindex == "strings" and "{Constant.String:" or "{Comment:") .. formatText( line ) .. "}"
			end
		end

		while i <= #line do
			local pat, fullindex = longestOf( line, i,
				lang.strings.start.line, lang.strings.start.multiline,
				lang.comments.start.line, lang.comments.start.multiline,
				"string_line", "string_multiline",
				"comment_line", "comment_multiline"
			)

			if pat then
				local index = fullindex:match "_(.+)"
				local sindex = (fullindex == "string_line" or fullindex == "string_multiline") and "strings" or "comments"
				local ending = findEndingMatch( line, pat, lang[sindex].finish[index], lang[sindex].escape and lang[sindex].escape[index], i + #pat )

				if ending then
					res = res .. (sindex == "strings" and "{Constant.String:" or "{Comment:") .. formatText( line:sub( i, ending ) ) .. "}"
					i = ending + 1
				else
					state.in_section = fullindex
					state.string_match = pat
					res = res .. (sindex == "strings" and "{Constant.String:" or "{Comment:") .. formatText( line:sub( i ) ) .. "}"
					return res
				end

			elseif line:find( "^%d*%.?%d", i ) then
				local match = line:match( "^%d*%.?%d+e[%+%-]%d+", i ) or line:match( "^%d*%.?%d+", i )
				res = res .. "{Constant.Number:" .. match .. "}"
				i = i + #match

			elseif line:find( "^0x%x", i ) then
				local match = line:match( "^0x%x+", i )
				res = res .. "{Constant.Number:" .. match .. "}"
				i = i + #match

			elseif line:find( "^[%w_]", i ) then
				local match = line:match( "^[%w_]+", i )

				if lang.keywords[match] then
					res = res .. "{" .. lang.keywords[match] .. ":" .. match .. "}"
				else
					res = res .. "{Constant.Identifier:" .. match .. "}"
				end
				i = i + #match

			else
				local l, v = 0
				for k, sv in pairs( lang.symbols ) do
					if line:sub( i, i + #k - 1 ) == k then
						if #k > l then
							l = #k
							v = sv
						end
					end
				end

				if l > 0 then
					res = res .. "{" .. v .. ":" .. formatText( line:sub( i, i + l - 1 ) ) .. "}"
					i = i + l
				else
					res = res .. formatText( line:sub( i, i ) )
					i = i + 1
				end
			end
		end

		return res

	end, {
		in_section = false;
		string_match = "";
	}
end

local function renderText(text, style, x, y)
	local i = 1
	local cstack = { lookupIndexInStyle( "_Default", style ) }
	local tstack = { "" }
	local list = {}
	local escaped = false

	while i <= #text do
		if not escaped and text:sub( i, i ) == "{" then
			list[#list + 1] = { text = tstack[#tstack], colour = cstack[#cstack] }
			tstack[#tstack] = ""
			tstack[#tstack + 1] = ""

			local name = text:match( "^(%w[%.%w]*%w):", i + 1 ) or text:match( "^(%w):", i + 1 ) or "" -- error instead here?

			cstack[#cstack + 1] = lookupIndexInStyle( name, style )
			i = i + #name + 2 -- + 1 for '{' and ':'
		elseif not escaped and text:sub( i, i ) == "}" then
			list[#list + 1] = { text = tstack[#tstack], colour = cstack[#cstack] }
			tstack[#tstack] = nil
			cstack[#cstack] = nil
			i = i + 1
		elseif not escaped and text:sub( i, i ) == "\\" then
			escaped = true
			i = i + 1
		else
			tstack[#tstack] = tstack[#tstack] .. text:sub( i, i )
			i = i + 1
		end

	end

	list[#list + 1] = { text = tstack[1], colour = cstack[1] }

	local font = love.graphics.getFont()

	for i =1, #list do
		love.graphics.setColor( list[i].colour )
		love.graphics.print( list[i].text, x, y )
		x = x + font:getWidth( list[i].text )
	end
end

editor = { }

function editor.load()
	love.keyboard.setKeyRepeat(true)

	editor.theme = themes.Default
	editor.lang = languages.lua
	editor.font = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 )

	editor.tab_spacing = 4

	editor.files = {
		[1] = {
			text = newTextBody( START_TEXT_LOOK_AT_START_OF_FILE ),
			cursor = {
				char = 1,
				line = 1,
			},
			selection = 0
		}
	}

	editor.c = {
		v = true,
		t = 0,
	}

	editor.workingfile = 1

	local fmt, state = createLanguageFormatter(editor.lang)
	local f = editor.files[1]

	function f.text:formatLine(state, line)
	      return fmt(state, line)
	end
	for k, v in pairs( state ) do
	    f.text.state[k] = v
	end

	editor.files[1].text:format()
end

function editor.update( dt )
	editor.c.t = editor.c.t + dt
	if editor.c.t > 0.5 then
		editor.c.t = editor.c.t - 0.5
		editor.c.v = not editor.c.v
	end
end

function editor.draw()
	local wf = editor.workingfile
	local f = editor.files[wf]

	love.graphics.setFont( editor.font )
	love.graphics.setBackgroundColor( editor.theme._Background )
	love.graphics.setColor( 255, 255, 255 )

	if editor.c.v then
		local line = f.text:get(f.cursor.line)
		local font = editor.font

		love.graphics.setColor( editor.theme._Default )
		love.graphics.rectangle("fill", 100+font:getWidth( line:sub( 1, f.cursor.char - 1 ):gsub("\t", (" "):rep( editor.tab_spacing))), 100+(f.cursor.line-1)*editor.font:getHeight(), editor.font:getWidth(" "), editor.font:getHeight())
	end

	for i=1, #f.text.lines do
		local line = f.text:getFormatted(i):gsub( "\t", (" "):rep(editor.tab_spacing) )
		renderText( line, editor.theme, 100, 100+(i-1)*editor.font:getHeight())
	end

	love.graphics.print( "Col " .. f.cursor.char .. " | Line " .. f.cursor.line, 10, love.graphics.getHeight()-50)
end

function editor.textinput( t )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.c.v = true
	editor.c.t = 0

	f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. t .. f.text:get(f.cursor.line):sub(f.cursor.char) )
	f.cursor.char = f.cursor.char + 1
end

function editor.keypressed( key )
	local wf = editor.workingfile
	local f = editor.files[wf]

	editor.c.v = true
	editor.c.t = 0

	if key == "backspace" then
		if f.cursor.line > 1 then
			if f.cursor.char > 0 then
				f.cursor.char = f.cursor.char - 1
			end
			f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. f.text:get(f.cursor.line):sub(f.cursor.char+1, #f.text:get(f.cursor.line)))
		else
			if f.cursor.char > 1 then
				f.cursor.char = f.cursor.char - 1
			end

			f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. f.text:get(f.cursor.line):sub(f.cursor.char+1, #f.text:get(f.cursor.line)))
		end
		if f.cursor.char == 0 and f.cursor.line > 1 then
			local t = f.text:get(f.cursor.line)
			f.cursor.line = f.cursor.line - 1
			f.cursor.char = #f.text:get(f.cursor.line)+1
			f.text:set(f.cursor.line, f.text:get(f.cursor.line)..t)
			f.text:remove(f.cursor.line+1)
		end
	elseif key == "return" then
		--print(f.text:get(f.cursor.line), f.cursor.char, f.cursor.line, #f.text:get(f.cursor.line))
		f.text:insert(f.cursor.line+1, f.text:get(f.cursor.line):sub(f.cursor.char, #f.text:get(f.cursor.line)))

		f.text:set( f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char))
		f.cursor.line = f.cursor.line + 1
		f.cursor.char = 1
	elseif key == "tab" then
		f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. "\t" .. f.text:get(f.cursor.line):sub(f.cursor.char) )
		f.cursor.char = f.cursor.char + 1
	elseif key == "up" then
		if f.cursor.line > 1 then
			if f.cursor.char == #f.text:get(f.cursor.line)+1 then
				f.cursor.char = #f.text:get(f.cursor.line-1)+1
			end
			f.cursor.line = f.cursor.line - 1
		end
	elseif key == "down" then
		if #f.text.lines >= f.cursor.line + 1 then
			f.cursor.line = f.cursor.line + 1
			if f.cursor.char == #f.text:get(f.cursor.line-1)+1 then
				f.cursor.char = #f.text:get(f.cursor.line)+1
			elseif f.cursor.char >= #f.text:get(f.cursor.line)+1 then
				f.cursor.char = #f.text:get(f.cursor.line)+1
			end
		end
	elseif key == "left" then
		if f.cursor.char == 1 and f.cursor.line > 1 then
			f.cursor.line = f.cursor.line -1
			f.cursor.char = #f.text:get(f.cursor.line)+1
		else
			f.cursor.char = f.cursor.char-1
		end
	elseif key == "right" then
		if f.cursor.char <= #f.text:get(f.cursor.line) then
			f.cursor.char = f.cursor.char + 1
		else
			if #f.text.lines > f.cursor.line then
				f.cursor.char = 1
				f.cursor.line = f.cursor.line + 1
			end
		end
	end
end
