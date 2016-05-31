
 -- NOTE: need to work on overlap

local function compare( a, b )
	return a[1] > b[1] or a[1] == b[1] and a[2] > b[2]
end

local function newCursorSystem()

	local s = {}

	s.cursors = {}

	function s:setCursor( cursor, line, character )
		self.cursors[cursor] = { cursor = { line, character }, selection = false }
	end

	function s:setCursorSelection( cursor, line, character )
		self.cursors[cursor].selection = line and { line, character } or false
	end

	function s:addCursor( line, character )
		self.cursors[#self.cursors + 1] = { cursor = { line, character }, selection = false }
	end

	function s:getCursor( cursor )
		return self.cursors[cursor].cursor
	end

	function s:getCursorSelection( cursor )
		return self.cursors[cursor].selection
	end

	function s:getCursorBounds( cursor ) -- returns min, max of the two cursors
		local c, s = self.cursors[cursor].cursor, self.cursors[cursor].selection
		if s then
			if compare(c, s) then
				return s, c
			end
			return c, s
		end
		return c
	end

	function s:getCursorCount()
		return #self.cursors
	end

	function s:getOrderedList()
		local t = {}

		for i = 1, #self.cursors do
			t[i] = { self:getCursorBounds( i ) }
		end

		table.sort( t, compare )
	end

	return s

end

return newCursorSystem
