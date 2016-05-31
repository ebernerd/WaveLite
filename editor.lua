--[[
newTextBody(string text)
- creates a new text object with the given starting text
- note: use :format() once created
:format(int i = 1, int j = #lines)
- updates the formatting on the range of lines given
:insert(int n, string line)
- inserts a new line and updates formatting
:remove(int n)
- removes a ling and updates formatting
:set(int n, string line)
- updates a line to a new value and updates the formatting
:get(int n)
- returns the raw line
:getFormatted(int n)
- returns the formatted line
:formatLine(table state, string line)
- (callback) returns a formatted string for that line
]]

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

local function newTextBody(text)

	local t = {}

	local lines = {}

	for line in text:gmatch "[^\n]*" do
		lines[#lines + 1] = line
	end

	if not t.state then
		t.state = {}
	end
	t.lines = lines
	t.fmtlines = {}
	t.states = { [0] = t.state }

	function t:format( i, upper )
		upper = upper or i or #self.lines
		i = i or 1

		while i <= upper and i <= #self.lines do

			local state = copyt( self.states[i - 1] ) -- this is for keeping track of things like (isInClass) to highlight keywords like 'super', 'private', etc
			self.fmtlines[i] = self:formatLine( state, self.lines[i] or "" )

			if i == upper and comparet( state, self.states[i] or {} ) then -- if the line caused the next to have a changed state
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
		return line -- with fancy text formatting
	end

	return t

end

editor = { }

local themes = {
	Default = {
		Keyword = {
			Loop = {
				_Default = { 255, 0, 0 },
			},
			Bool = {
				_Default = { 0, 255, 0 },
			},
			Function = {
				_Default = { 48, 163, 201 }
			},
			Declare = {
				_Default = { 201, 76, 48 },
			},
			Control = {
				_Default = { 201, 48, 156 },
			},
			_Default = { 48, 201, 84 },
		},
		Operator = {
			_Default = { 121, 250, 70 }
		},
		Contstant = {
			_Default = { 250, 70, 230 }
		},
		Symbol = {
			_Default = { 40, 40, 40 }
		},
		Comment = {
			_Default = { 140, 140, 140 }
		},
		String = {
			_Default = { 230, 172, 16 }
		},

		_Default = { 40, 40, 40 },
		_Background = { 230, 230, 230 }
	}
}

local languages = {}

local lang_lua = {
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
			line = "\n";
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

local function findEndingMatch( text, initial, final, escape, position )
	if not final then error("hey", 2)end
	local escaped = false
	local close = "^" .. initial:gsub( "^(.*)$", final )
	local esc = escape and "^" .. initial:gsub( "^(.*)$", escape )

	while position <= #text do
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
	local l = 0
	local n = 0

	for i = 1, #t do
		if t[i][2] and #t[i][2] > l then
			n = i
		end
	end

	return n > 0 and text:match( "^" .. t[n][1], position ), n > 0 and ({A, B, C, D})[n]
end

local function formatText( text )
	return text:gsub( "\\", "\\\\" ):gsub( "{", "\\{" ):gsub( "}", "\\}" )
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
				elseif fullindex == "comment_line" then
					res = res .. (sindex == "strings" and "{Constant.String:" or "{Comment:") .. formatText( line:sub( i ) ) .. "}"
					return res
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
				else
					res = res .. formatText( line:sub( i, i ) )
				end

				i = i + 1
			end
		end

		return res

	end, {
		in_section = false;
		string_match = "";
	}
end

languages.lua = lang_lua

editor.theme = themes.Default
editor.lang = languages.lua

local function lookupIndexInStyle(index, style)
	for part in index:gmatch "[^%.]+" do
		style = style[part] or style._Default or style
	end
	return style._Default or style
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

	for i =1, #list do

		love.graphics.setColor( list[i].colour )
		love.graphics.print( list[i].text, x, y )

		local font = love.graphics.getFont()
		x = x + font:getWidth( list[i].text )
	end
end

function editor.load()
	editor.font = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 )
	editor.files = {
		[1] = {
			text = newTextBody("", editor.lang),
			lines = { [1] = "" },
			cursor = {
				char = 1,
				line = 1,
			},
			selection = 0
		}
	}
	local fmt, state = createLanguageFormatter(editor.lang)
	local f = editor.files[1]
	function f.text:formatLine(state, line)
	      return fmt(state, line)
	end
	for k, v in pairs( state ) do
	    f.text.state[k] = v
	end
	editor.c = {
		v = true,
		t = 0,
	}
	editor.workingfile = 1
	editor.files[1].text:format()
end

function editor.update( dt )
	editor.c.t = editor.c.t + dt
	if editor.c.t > 0.5 then
		editor.c.t = 0
		editor.c.v = not editor.c.v
	end
end

function editor.draw()
	love.graphics.setFont( editor.font )
	love.graphics.setBackgroundColor( editor.theme._Background )
	local f = editor.files[editor.workingfile]
	love.graphics.setColor( 255, 255, 255 )
	local wf = editor.workingfile
	for i=1, #f.lines do
		renderText( f.text:getFormatted(i), editor.theme, 100, 100+(i-1)*editor.font:getHeight())
	end
	love.graphics.print( "Col " .. f.cursor.char .. " | Line " .. f.cursor.line, 10, love.graphics.getHeight()-50)
	if editor.c.v then
		love.graphics.setColor( editor.theme._Default )
		love.graphics.rectangle("fill", 100+(f.cursor.char-1)*editor.font:getWidth(" "), 100+(f.cursor.line-1)*editor.font:getHeight(), editor.font:getWidth(" "), editor.font:getHeight())
		if f.cursor.char <= #f.text:get(f.cursor.line) then
			love.graphics.setColor( editor.theme._Background )
			love.graphics.print(f.text:get(f.cursor.line):sub(f.cursor.char, f.cursor.char), 100, 100+(f.cursor.line-1)*editor.font:getHeight())
		end
	end
end

function editor.textinput( t )
	editor.c.v = true
	editor.c.t = 0
	local f = editor.files[editor.workingfile]
	f.text:set(f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char-1) .. t .. f.text:get(f.cursor.line):sub(f.cursor.char, #f.text:get(f.cursor.line)) )
	f.cursor.char = f.cursor.char + 1
end

function editor.keypressed( key )
	editor.c.v = true
	editor.c.t = 0
	f = editor.files[editor.workingfile]
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
			table.remove( f.lines, f.cursor.line + 1)
		end
	elseif key == "return" then
		--print(f.text:get(f.cursor.line), f.cursor.char, f.cursor.line, #f.text:get(f.cursor.line))
		f.text:insert(f.cursor.line+1, f.text:get(f.cursor.line):sub(f.cursor.char, #f.text:get(f.cursor.line)))

		table.insert( f.lines, f.cursor.line+1, f.text:get(f.cursor.line):sub(f.cursor.char, #f.text:get(f.cursor.line)))

		f.text:set( f.cursor.line, f.text:get(f.cursor.line):sub(1, f.cursor.char))
		f.cursor.line = f.cursor.line + 1
		f.cursor.char = 1
	elseif key == "up" then
		if f.cursor.line > 1 then
			if f.cursor.char == #f.text:get(f.cursor.line)+1 then
				f.cursor.char = #f.text:get(f.cursor.line-1)+1
			end
			f.cursor.line = f.cursor.line - 1
		end
	elseif key == "down" then
		if #f.lines >= f.cursor.line + 1 then
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
			if #f.lines > f.cursor.line then
				f.cursor.char = 1
				f.cursor.line = f.cursor.line + 1
			end
		end
	end
end
