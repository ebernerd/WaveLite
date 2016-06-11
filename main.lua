
local function copy( a, b )
	if love.filesystem.isDirectory( a ) then
		for i, file in ipairs( love.filesystem.getDirectoryItems( a ) ) do
			copy( a .. "/" .. file, b .. "/" .. file )
		end
	else
		love.filesystem.write( b, love.filesystem.read( a ) )
	end
end

if not love.filesystem.isDirectory "plugins" then
	copy( "data/plugins", "plugins" )
end
if not love.filesystem.isDirectory "user" then
	copy( "data/user", "user" )
end
if not love.filesystem.isDirectory "resources" then
	copy( "data/resources", "resources" )
end

local UIPanel = require "src.elements.UIPanel"
local plugin = require "src.lib.plugin"
local WaveLite = require "src.WaveLite"

-- require "src.ser" --table serialization
-- options = require "src.options"
-- packages = require "src.packages"

local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
local down = {}

local function newEvent( t )
	t.handled = false

	function t:handle()
		self.handled = true
	end

	return t
end

local function newMouseEvent( t )
	function t:isWithin( width, height )
		return self.x >= 0 and self.y >= 0 and self.x < width and self.y < height
	end

	function t:child( x, y )
		local sub = newMouseEvent( newEvent( setmetatable( { x = self.x - x, y = self.y - y }, { __index = self } ) ) )

		sub.handled = self.handled

		function sub.handle()
			sub.handled = true
			self:handle()
		end

		return sub
	end

	return t
end

function love.load()
	love.keyboard.setKeyRepeat( true )
	WaveLite.load()
end

function love.update(dt)
	plugin.update( dt )
	UIPanel.main:update( dt )
end

function love.touchpressed(ID, x, y)
	UIPanel.main:handle( newMouseEvent( newEvent { type = "touch", x = x, y = y, ID = ID } ) )
end

function love.touchreleased(ID, x, y)
	UIPanel.main:handle( newMouseEvent( newEvent { type = "release", x = x, y = y, ID = ID } ) )
end

function love.touchmoved(ID, x, y)
	UIPanel.main:handle( newMouseEvent( newEvent { type = "move", x = x, y = y, ID = ID } ) )
end

function love.wheelmoved( x, y )
	UIPanel.main:handle( newMouseEvent( newEvent { type = "wheel", x = love.mouse.getX(), y = love.mouse.getY(), xd = x, yd = y } ) )
end

function love.keypressed(key)
	UIPanel.main:handle( newEvent { type = "keypress", key = key } )
end

function love.keyreleased(key)
	UIPanel.main:handle( newEvent { type = "keyrelease", key = key } )
end

function love.textinput(text)
	UIPanel.main:handle( newEvent { type = "textinput", text = text } )
end

function love.draw()
	UIPanel.main:draw()
end

if not isMobile then
	function love.mousepressed(x, y, button)
		down[button] = true
		return love.touchpressed(button, x, y)
	end

	function love.mousereleased(x, y, button)
		down[button] = nil
		return love.touchreleased(button, x, y)
	end

	function love.mousemoved(x, y)
		for v in pairs( down ) do
			love.touchmoved(v, x, y)
		end
	end
end
