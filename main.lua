
require "resources.plugins.core"
require "resources.plugins.custom"

-- require "src.ser" --table serialization
-- options = require "src.options"
-- packages = require "src.packages"

local editor = require "src.editor"
local UIPanel = require "src.UIPanel"

local editor = require "src.CodeEditor" ()

editor.panel.x = 100
editor.panel.y = 100
editor.panel:resize( 600, 400 )
editor.panel:focus()

UIPanel.main:add( editor.panel )


local editor2 = require "src.CodeEditor" ()

editor2.panel.x = 750
editor2.panel.y = 50
editor2.panel:resize( 200, 300 )
editor2.style = require "resources.styles.dark"

UIPanel.main:add( editor2.panel )


local editor3 = require "src.CodeEditor" ()

editor3.panel.x = 300
editor3.panel.y = 200
editor3.panel:resize( 300, 250 )

UIPanel.main:add( editor3.panel )

function love.load()
	love.keyboard.setKeyRepeat( true )
end

function love.update(dt)
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
