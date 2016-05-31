
local editor = require "editor"
local UIPanel = require "lib.UIPanel"

function love.load()
	editor.load()
end

function love.update(dt)
	editor.update( dt )
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
	editor.keypressed(key)
end

function love.keyreleased(key)
	-- key releasy stuff
end

function love.textinput(text)
	editor.textinput( text )
end

function love.draw()
	UIPanel.main:draw()
end

function love.wheelmoved( x, y )
	editor.wheelmoved( x, y )
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
