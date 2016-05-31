
	function t:backspace( start, finish )
		if finish then
			return self:write( "", start, finish )
		else
			if start[2] == 1 then
				if start[1] > 1 then
					local char = #self.lines[start[1] - 1] + 1
					
					self.lines[start[1] - 1] = self.lines[start[1] - 1] .. self.lines[start[1]]
					
					table.remove( self.lines, start[1] )
					table.remove( self.fmtlines, start[1] )
					table.remove( self.states, start[1] )

					self:format( start[1] - 1 )

					return {start[1] - 1, char}
				end
				return start
			else
				self.lines[start[1]] = self.lines[start[1]]:sub( 1, start[2] - 2 ) .. self.lines[start[1]]:sub( start[2] )
				self:format( start[1] )
				return {start[1], start[2] - 1}
			end
		end
	end

	function t:delete( start, finish )
		if finish then
			return self:write( "", start, finish )
		else
			if start[2] == #self.lines[start[1]] + 1 then
				if start[1] < #self.lines then
					self.lines[start[1]] = self.lines[start[1]] .. self.lines[start[1] + 1]
					
					table.remove( self.lines, start[1] + 1 )
					table.remove( self.fmtlines, start[1] + 1 )
					table.remove( self.states, start[1] + 1 )

					self:format( start[1] )
				end
				return start
			else
				self.lines[start[1]] = self.lines[start[1]]:sub( 1, start[2] - 1 ) .. self.lines[start[1]]:sub( start[2] + 1 )
				self:format( start[1] )
				return {start[1], start[2]}
			end
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
