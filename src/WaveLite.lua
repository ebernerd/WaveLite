
local UIPanel = require "src.elements.UIPanel"
local style = require "src.style"
local plugin = require "src.lib.plugin"

local WaveLite = {}

WaveLite.style_UI = style.new()
WaveLite.style_code = style.new()

function WaveLite.load()
	plugin.load( "core", "resources/plugins/core.lua" )
	plugin.load( "custom", "resources/plugins/custom.lua" )

	-- global configs, settings, reference to main pane handler, etc

	local tabs = require "src.elements.TabManager" ()
	local editor = tabs.api.open( "blank", "thing" )

	for i = 1, 10 do
		tabs.api.open( "content", "\n -- This is some stuff for tab " .. i .. "\n", "thing " .. i )
	end

	editor.focus()

	tabs.x = 200
	tabs.y = 100
	tabs:resize( 600, 400 )

	function tabs:onParentResized()
		self:resize( self.parent.width - self.x - 10, self.parent.height - self.y - 10 )
	end

	UIPanel.main:add( tabs )
end

return WaveLite
