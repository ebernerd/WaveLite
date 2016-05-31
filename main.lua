
local editor = require "editor"

function love.load()
	editor.load()
end

function love.update(dt)
	editor.update( dt )
end

function love.touchpressed(ID, x, y)
	-- touch pressy stuff
end

function love.touchreleased(ID, x, y)
	-- touch releasy stuff
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
	editor.draw()
end

if love.system.getOS() ~= "Android" and love.system.getOS() ~= "iOS" then
	function love.mousepressed(x, y, button)
		return love.touchpressed(button, x, y)
	end

	function love.mousereleased(x, y, button)
		return love.touchreleased(button, x, y)
	end
end
