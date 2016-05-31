
local touches = {}
local scissors = {}

local function globalX( child )
	return child.x + ( child.parent and globalX( child.parent ) or 0 )
end

local function globalY( child )
	return child.y + ( child.parent and globalY( child.parent ) or 0 )
end

local function findRecursive( x, y, children )
	for i = #children, 1, -1 do
		if children[i].visible and x >= children[i].x and y >= children[i].y and x < children[i].x + children[i].width and y < children[i].y + children[i].height then
			local child = findRecursive( x - children[i].x, y - children[i].y, children[i].children ) or children[i].enable_mouse and children[i]
			if child then
				return child
			end
		end
	end
end

local function findKeyRecursive( children )
	for i = #children, 1, -1 do
		if children[i].visible then
			local child = findKeyRecursive( children[i].children ) or children[i].enable_keyboard and children[i]
			if child then
				return child
			end
		end
	end
end

local function newUIPanel( x, y, width, height )

	local panel = {}

	panel.x = x or 0
	panel.y = y or 0
	panel.width = width or 0
	panel.height = height or 0
	panel.parent = nil
	panel.children = {}
	panel.visible = true
	panel.enable_keyboard = false
	panel.enable_mouse = true

	panel.colour = { 240, 240, 240 }

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

	function panel:draw( x, y )
		x, y = x or 0, y or 0
		scissors[#scissors + 1] = { x + self.x, y + self.y, self.width, self.height }

		love.graphics.push()
			love.graphics.intersectScissor( x + self.x, y + self.y, self.width, self.height )
			love.graphics.translate( self.x, self.y )

			self:onDraw "before"
			for i = 1, #self.children do
				if self.children[i].visible then
					self.children[i]:draw( x + self.x, y + self.y )
				end
			end
			self:onDraw "after"
		love.graphics.pop()

		scissors[#scissors] = nil
		if scissors[1] then
			love.graphics.setScissor(unpack(scissors[1]))

			for i = 2, #scissors do
				love.graphics.intersectScissor(unpack(scissors[i]))
			end
		else
			love.graphics.setScissor()
		end
	end

	function panel:update( dt )
		self:onUpdate( dt )
		for i = 1, #self.children do
			self.children[i]:update( dt )
		end
	end

	function panel:onUpdate( dt )

	end

	function panel:onDraw(mode)
		if mode == "before" then
			love.graphics.setColor( self.colour )
			love.graphics.rectangle( "fill", 0, 0, self.width, self.height )
		end
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

	return panel

end

local main = newUIPanel( 0, 0, 0, 0 )

function main:onUpdate()
	self:resize( love.window.getMode() )
end

function main:onTouch( x, y, ID )
	local child = findRecursive( x, y, self.children )

	if child then
		child:onTouch( x - globalX(child), y - globalY(child), ID )
		touches[#touches + 1] = { child, ID }
	end
end

function main:onRelease( x, y, ID )
	for i = #touches, 1, -1 do
		if touches[i][2] == ID then
			touches[i][1]:onRelease( x - globalX(touches[i][1]), y - globalY(touches[i][1]), touches[i][2] )
		end
		table.remove( touches, i )
	end
end

function main:onMove( x, y )
	for i = 1, #touches do
		touches[i][1]:onMove( x - globalX(touches[i][1]), y - globalY(touches[i][1]), touches[i][2] )
	end
end

function main:onKeypress( key )
	local child = findKeyRecursive( self.children )

	if child then
		child:onKeypress( key )
	end
end

function main:onKeyrelease( key )
	local child = findKeyRecursive( self.children )

	if child then
		child:onKeyrelease( key )
	end
end

function main:onTextInput( key )
	local child = findKeyRecursive( self.children )

	if child then
		child:onTextInput( key )
	end
end

local body = main:add( newUIPanel( 0, 0, 0, 0 ) )
local popup = main:add( newUIPanel( 0, 0, 0, 0 ) )

body.enable_mouse = false
popup.enable_mouse = false

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
