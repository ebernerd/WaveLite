
local UIPanel = require "src.elements.UIPanel"

local function newDivisions( direction, ... )

	local div = UIPanel.new( ... )

	div.type = "division"
	div.direction = direction or "vertical"
	div.divider_bound = 0

	function div:add( object, insertion )
		local i = 1

		while self.children[i] and self.children[i] ~= insertion do
			i = i + 1
		end

		table.insert( self.children, i, object )
		object.parent = self

		local objectsize = math.floor( (self.direction == "vertical" and self.height or self.width) / #self.children )
		local xr = (self.width - ( self.direction == "vertical" and 0 or objectsize )) / self.width
		local yr = (self.height - ( self.direction == "vertical" and objectsize or 0 )) / self.height
		local t = 0

		if #self.children == 1 then

			object.width = self.direction == "vertical" and self.width or objectsize
			object.height = self.direction == "vertical" and objectsize or self.height

		else

			object.width = self.direction == "vertical" and self.width or objectsize / xr
			object.height = self.direction == "vertical" and objectsize / yr or self.height

			for i = 1, #self.children do
				self.children[i].x = self.direction == "vertical" and 0 or t
				self.children[i].y = self.direction == "vertical" and t or 0

				if self.direction == "vertical" then
					self.children[i]:resize( self.width, self.children[i].height * yr )
				else
					self.children[i]:resize( self.children[i].width * xr, self.height )
				end

				t = t + (self.direction == "vertical" and self.children[i].height or self.children[i].width)
			end

		end

		return object
	end

	function div:remove( child )
		for i = 1, #self.children do
			if self.children[i] == child then
				child.parent = nil
				table.remove( self.children, i )

				local objectsize = self.direction == "vertical" and child.height or child.width
				local xr = self.width / (self.width - ( self.direction == "vertical" and 0 or objectsize ))
				local yr = self.height / (self.height - ( self.direction == "vertical" and objectsize or 0 ))
				local t = 0

				for i = 1, #self.children do
					self.children[i].x = self.direction == "vertical" and 0 or t
					self.children[i].y = self.direction == "vertical" and t or 0

					if self.direction == "vertical" then
						self.children[i]:resize( self.width, self.children[i].height * yr )
					else
						self.children[i]:resize( self.children[i].width * xr, self.height )
					end

					t = t + (self.direction == "vertical" and self.children[i].height or self.children[i].width)
				end

				return child
			end
		end
	end

	function div:handleprev( event )
		if not self.visible then return end

		if not event.handled and event.type == "touch" and self.enable_mouse and event:isWithin( self.width, self.height ) then
			self.touches[event.ID] = { x = event.x, y = event.y, time = os.clock(), moved = false }
			self:focus()

			local t = 0

			for i = 1, #self.children - 1 do
				t = t + (self.direction == "vertical" and self.children[i].height or self.children[i].width)

				if math.abs( t - (self.direction == "vertical" and event.y or event.x) ) < 3 then
					self.divider_bound = i
					self.child_one_size = self.children[self.divider_bound][self.direction == "vertical" and "height" or "width"]
					self.child_two_size = self.children[self.divider_bound + 1][self.direction == "vertical" and "height" or "width"]
					self.child_two_pos = self.children[self.divider_bound + 1][self.direction == "vertical" and "y" or "x"]
				
					event:handle()

					break
				else
					self.divider_bound = false
				end
			end

		elseif event.type == "move" and self.enable_mouse and self.touches[event.ID] then
			local dx, dy = event.x - self.touches[event.ID].x, event.y - self.touches[event.ID].y
			self.touches[event.ID].moved = self.touches[event.ID].moved or dx * dx + dy * dy >= 16
			
			if self.divider_bound and self.children[self.divider_bound] and self.children[self.divider_bound + 1] then
				local diff = self.direction == "vertical" and event.y - self.touches[event.ID].y or event.x - self.touches[event.ID].x

				if self.direction == "vertical" then
					self.children[self.divider_bound + 1]:resize( self.children[self.divider_bound + 1].width, self.child_two_size - diff )
					self.children[self.divider_bound + 1].y = self.child_two_pos + diff
					self.children[self.divider_bound]:resize( self.children[self.divider_bound].width, self.child_one_size + diff )
				else
					self.children[self.divider_bound + 1]:resize( self.child_two_size - diff, self.children[self.divider_bound + 1].height )
					self.children[self.divider_bound + 1].x = self.child_two_pos + diff
					self.children[self.divider_bound]:resize( self.child_one_size + diff, self.children[self.divider_bound].height )
				end
			end

			event:handle()

		elseif event.type == "release" and self.enable_mouse and self.touches[event.ID] then
			self:onRelease( event.x, event.y, event.ID )
			self.touches[event.ID] = nil
			event:handle()

		end
	end

	function div:resize( w, h )
		if w ~= self.width or h ~= self.height then

			local xr = w / self.width
			local yr = h / self.height
			local t = 0

			for i = 1, #self.children do
				self.children[i].x = self.direction == "vertical" and 0 or t
				self.children[i].y = self.direction == "vertical" and t or 0

				if self.direction == "vertical" then
					self.children[i]:resize( w, self.children[i].height * yr )
				else
					self.children[i]:resize( self.children[i].width * xr, h )
				end

				t = t + (self.direction == "vertical" and self.children[i].height or self.children[i].width)
			end

			self.width = w
			self.height = h

			for i = 1, #self.children do
				self.children[i]:onParentResized()
			end

		end
	end

	return div

end

return newDivisions
