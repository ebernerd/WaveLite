
local scissor = require "src.lib.scissor"

local touches = {}
local focussed = nil

local function globalX( child )
	return child.x + ( child.parent and globalX( child.parent ) or 0 )
end

local function globalY( child )
	return child.y + ( child.parent and globalY( child.parent ) or 0 )
end

local function newUIPanel( x, y, width, height )

	local panel = {}

	panel.type = "panel"
	panel.x = x or 0
	panel.y = y or 0
	panel.width = width or 1
	panel.height = height or 1
	panel.parent = nil
	panel.children = {}
	panel.visible = true
	panel.enable_keyboard = false
	panel.enable_mouse = true
	panel.touches = {}
	panel.focussed = false
	panel.colour = { 250, 250, 250 }

	function panel:add( child )
		self.children[#self.children + 1] = child
		child.parent = self
		return child
	end

	function panel:remove( child )
		for i = 1, #self.children do
			if self.children[i] == child then
				child.parent = nil
				table.remove( self.children, i )
				return child
			end
		end
	end

	function panel:replaceChild( child, new )
		for i = 1, #self.children do
			if self.children[i] == child then
				new.x = child.x
				new.y = child.y
				new.width = child.width
				new.height = child.height

				self.children[i] = new
				self.children[i].parent = nil

				new.parent = self

				return child
			end
		end

		return new
	end

	function panel:nextChild( child, loop )
		for i = 1, #self.children do
			if self.children[i] == child then
				if i == #self.children then
					return loop and self.children[1] or nil
				else
					return self.children[i + 1]
				end
			end
		end
	end

	function panel:previousChild( child, loop )
		for i = 1, #self.children do
			if self.children[i] == child then
				if i == 1 then
					return loop and self.children[#self.children] or nil
				else
					return self.children[i - 1]
				end
			end
		end
	end

	function panel:childOfType( type )
		if self.type == type then
			return self
		end
		for i = #self.children, 1, -1 do
			local c = self.children[i]:childOfType( type )
			if c then
				return c
			end
		end
	end

	function panel:focus()
		if focussed ~= self then
			if focussed then
				focussed:onUnFocus( self )
				focussed.focussed = false
			end
			self:onFocus( focussed )
			focussed = self
			self.focussed = true
		end
	end

	function panel:unfocus()
		if focussed == self then
			focussed:onUnFocus()
			focussed = nil
			self.focussed = false
		end
	end

	function panel:draw( x, y )
		x, y = x or 0, y or 0

		love.graphics.push()
			scissor.push( x + self.x, y + self.y, self.width, self.height )
			love.graphics.translate( self.x, self.y )

			self:onDraw "before"
			for i = 1, #self.children do
				if self.children[i].visible then
					self.children[i]:draw( x + self.x, y + self.y )
				end
			end
			self:onDraw "after"
			scissor.pop()
		love.graphics.pop()
	end

	function panel:update( dt )
		self:onUpdate( dt )
		for i = 1, #self.children do
			self.children[i]:update( dt )
		end
	end

	function panel:onUpdate( dt )

	end

	function panel:onDraw( stage )
		if stage == "before" then
			love.graphics.setColor( self.colour )
			love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
		end
	end

	function panel:onWheelMoved( x, y )

	end

	function panel:onTouch( x, y, ID )

	end

	function panel:onRelease( x, y, ID )

	end

	function panel:onMove( x, y, ID )

	end

	function panel:onKeypress( key )

	end

	function panel:onKeyrelease( key )

	end

	function panel:onTextInput( text )

	end

	function panel:resize( w, h )
		if w ~= self.width or h ~= self.height then
			self.width, self.height = w, h

			for i = 1, #self.children do
				self.children[i]:onParentResized( self )
			end
		end
	end

	function panel:onParentResized( parent )

	end

	function panel:onFocus( sibling )

	end

	function panel:onUnFocus( sibling )

	end

	function panel:handle( event )
		if not self.visible then return end

		if self.handleprev then
			self:handleprev( event )
		end

		local isTouchEvent = event.type == "touch" or event.type == "move" or event.type == "release" or event.type == "wheel" or event.type == "ping"

		for i = #self.children, 1, -1 do
			self.children[i]:handle( isTouchEvent and event:child( self.children[i].x, self.children[i].y ) or event )
		end

		if not event.handled and event.type == "touch" and self.enable_mouse and event:isWithin( self.width, self.height ) then
			self.touches[event.ID] = { x = event.x, y = event.y, time = os.clock(), moved = false }
			self:focus()
			self:onTouch( event.x, event.y, event.ID )
			event:handle()

		elseif event.type == "move" and self.enable_mouse and self.touches[event.ID] then
			local dx, dy = event.x - self.touches[event.ID].x, event.y - self.touches[event.ID].y
			self.touches[event.ID].moved = self.touches[event.ID].moved or dx * dx + dy * dy >= 16
			self:onMove( event.x, event.y, event.ID )
			event:handle()

		elseif event.type == "release" and self.enable_mouse and self.touches[event.ID] then
			self:onRelease( event.x, event.y, event.ID )
			self.touches[event.ID] = nil
			event:handle()

		elseif not event.handled and event.type == "wheel" and self.enable_mouse and event:isWithin( self.width, self.height ) then
			self:onWheelMoved( event.xd, event.yd )
			event:handle()

		elseif event.type == "ping" and self.enable_mouse then
			event:handle()

		elseif not event.handled and self.focussed and event.type == "keypress" and self.enable_keyboard then
			self:onKeypress( event.key )
			event:handle()

		elseif not event.handled and self.focussed and event.type == "keyrelease" and self.enable_keyboard then
			self:onKeyrelease( event.key )
			event:handle()

		elseif not event.handled and self.focussed and event.type == "textinput" and self.enable_keyboard then
			self:onTextInput( event.text )
			event:handle()

		end
	end

	return panel

end

local main = newUIPanel()

function main:onUpdate()
	self:resize( love.window.getMode() )
end

local body = main:add( newUIPanel() )
local popup = main:add( newUIPanel() )

function body:onDraw() end
function popup:onDraw() end

function body:onParentResized()
	self:resize( self.parent.width, self.parent.height )
end

function popup:onParentResized()
	self:resize( self.parent.width, self.parent.height )
end

return {
	new = newUIPanel;
	main = main;
	body = body;
	popup = popup;
}
