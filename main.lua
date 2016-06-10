
local UIPanel = require "src.elements.UIPanel"
local plugin = require "src.lib.plugin"
local WaveLite = require "src.WaveLite"

-- require "src.ser" --table serialization
-- options = require "src.options"
-- packages = require "src.packages"

function love.load()
	love.keyboard.setKeyRepeat( true )
	WaveLite.load()
end

function love.update(dt)
	plugin.update( dt )
	UIPanel.main:update( dt )
end

function love.touchpressed(ID, x, y)
	UIPanel.main:onTouch(x, y, ID)
end

function love.touchreleased(ID, x, y)
	UIPanel.main:onRelease(x, y, ID)
end

function love.touchmoved(ID, x, y)
	UIPanel.main:onMove(x, y)
end

function love.keypressed(key)
	UIPanel.main:onKeypress(key)
end

function love.keyreleased(key)
	UIPanel.main:onKeyrelease(key)
end

function love.textinput(text)
	UIPanel.main:onTextInput(text)
end

function love.draw()
	UIPanel.main:draw()
end

function love.wheelmoved( x, y )
	UIPanel.main:onWheelMoved( x, y )
end

if love.system.getOS() ~= "Android" and love.system.getOS() ~= "iOS" then
	function love.mousepressed(x, y, button)
		return love.touchpressed(button, x, y)
	end

	function love.mousereleased(x, y, button)
		return love.touchreleased(button, x, y)
	end

	function love.mousemoved(x, y)
		return love.touchmoved(_, x, y)
	end
end
