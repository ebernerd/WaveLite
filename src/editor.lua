
local UIPanel = require "src.UIPanel"
local util = require "src.util"
local cursor = require "src.cursor"
local formatting = require "src.formatting"
local text_editor = require "src.text_editor"
local rendering = require "src.rendering"
local text_window = require "src.text_window"

local DEFAULT_FONT = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 )
local PADDING_TOPLEFT = 100
local PADDING_BOTTOMRIGHT = 20
local TABS = "    "

local editor = {}

editor.files = {}
editor.workingfile = 1

editor.panel = UIPanel.body:add( UIPanel.new() )
editor.scroll_right = editor.panel:add( UIPanel.new() )
editor.scroll_bottom = editor.panel:add( UIPanel.new() )

editor.cursor_blink = {
	timer = 0;
	state = true;
}

function editor.getContentWidth()

end

function editor.getContentHeight()

end

function editor.getDisplayWidth()

end

function editor.getDisplayHeight()

end

function editor.open( filename, filecontent )
	local t = {
		filename = filename;
		lines = util.splitlines( filecontent );
		formatting = {
			lines = {};
			states = { [0] = {} };
			formatter = function(text) return util.formatText( text ) end;
		};
		cursors = { cursor.new() };
		style = {};
		scrollX = 0;
		scrollY = 0;

		onSave = function(self, content) end;
		onClose = function(self, content) end;
	}

	t.style.font = DEFAULT_FONT
	t.style.default = { 40, 40, 40 }
	formatting.format( t.lines, t.formatting )

	editor.files[#editor.files + 1] = t

	return t
end

function editor.file()
	return editor.files[editor.workingfile]
end

function editor.wheelmoved( x, y )

end

function editor.panel:onParentResized( parent )
	self.x = PADDING_TOPLEFT
	self.y = PADDING_TOPLEFT
	self.width = parent.width - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT
	self.height = parent.height - PADDING_TOPLEFT - PADDING_BOTTOMRIGHT
end

function editor.panel:onUpdate( dt )
	editor.cursor_blink.timer = editor.cursor_blink.timer + dt

	if editor.cursor_blink.timer >= 0.5 then
		editor.cursor_blink.timer = 0
		editor.cursor_blink.state = not editor.cursor_blink.state
	end
end

function editor.panel:onDraw(mode)
	if mode == "after" then
		local file = editor.file()
		love.graphics.setColor( 180, 180, 180 ) -- change this!
		for i, cursor in ipairs( editor.file().cursors ) do
			local cx, cy = #file.lines[cursor.position[1]]:sub(1, cursor.position[2] - 1):gsub( "\t", TABS ), cursor.position[1]
			local x, y = text_window.locationToPixels( cx, cy, file.style.font )
			love.graphics.line( x, y, x, y + file.style.font:getHeight())
		end
		-- draw highlighting
		love.graphics.setColor( 180, 180, 180 ) -- change this!
		love.graphics.rectangle( "line", 0, 0, self.width, self.height )
		rendering.formatted_text_lines( editor.file().formatting.lines, editor.file().style, -editor.file().scrollX, -editor.file().scrollY, self.width, self.height )
	end
end

function editor.panel:onTouch( x, y )

end

function editor.panel:onMove( x, y )

end

function editor.panel:onRelease( x, y )

end

function editor.panel:onKeypress( key )

end

function editor.panel:onKeyrelease( key )

end

function editor.panel:onTextInput( text )

end

function editor.load()
	editor.open( "untitled", [[
	this is a string
	of awesome text
	that's really cool]] )
end

return editor
