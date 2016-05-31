
local util = require "lib.util"

local function splitlines( text )
	local lines = { "" }

	for i = 1, #text do
		if text:sub( i, i ) == "\n" then
			lines[#lines + 1] = ""
		else
			lines[#lines] = lines[#lines] .. text:sub( i, i )
		end
	end

	return lines
end

local function newTextBody(text)

	local t = {}

	t.state = {}
	t.lines = splitlines( text )
	t.fmtlines = {}
	t.states = setmetatable( { [0] = t.state }, { __index = function(t, i) return t[i-1] end } )

	function t:write( text, start, finish )

		if finish then
			-- remove old text
			self.lines[start[1]] = self.lines[start[1]]:sub( 1, start[2] - 1 ) .. self.lines[finish[1]]:sub( finish[2] )
			for i = start[1] + 1, finish[1] do
				table.remove( self.lines, i )
				table.remove( self.fmtlines, i )
				table.remove( self.states, i )
			end
		end

		local lines = splitlines( text )

		if #lines == 1 then
			self.lines[start[1]] = self.lines[start[1]]:sub( 1, start[2] - 1 ) .. text .. self.lines[start[1]]:sub( start[2] )
		else
			for i = 2, #lines do
				local n = start[1] + i - 1
				table.insert( self.lines, n, lines[i] )
				table.insert( self.fmtlines, n, "" )
				table.insert( self.states, n, {} )
			end

			self.lines[start[1] + #lines - 1] = self.lines[start[1] + #lines - 1] .. self.lines[start[1]]:sub( start[2] )
			self.lines[start[1]] = self.lines[start[1]]:sub( 1, start[2] - 1 ) .. lines[1]
		end

		self:format( start[1], start[1] + #lines - 1 )

	end

	function t:format( i, upper )
		upper = upper or i or #self.lines
		i = i or 1

		while i <= upper and i <= #self.lines do

			local state = util.copyt( self.states[i - 1] ) -- this is for keeping track of things like (isInClass) to highlight keywords like 'super', 'private', etc
			self.fmtlines[i] = self:formatLine( state, self.lines[i] )

			if i == upper and util.comparet( state, self.states[i] ) then -- if the line caused the next to have a changed state
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
		return util.formatText( line ) -- with fancy text formatting
	end

	return t

end

return newTextBody
