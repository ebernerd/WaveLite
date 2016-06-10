
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

	local split = require "src.elements.Divisions" "horizontal"
	local tabs = split:add( require "src.elements.TabManager" () )
	local editor = tabs.api.open "content" .focus()

	split.x = 200
	split.y = 100

	function split:onParentResized()
		self:resize( self.parent.width - self.x - 10, self.parent.height - self.y - 10 )
	end

	UIPanel.main:add( split )

	require "src.lib.event" .bind( "editor:key:ctrl-shift-t", function()
		local tabs = split:add( require "src.elements.TabManager" () )
		tabs.api.open "content" .focus()
	end )
end

return WaveLite
