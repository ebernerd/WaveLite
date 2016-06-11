
local UIPanel = require "src.elements.UIPanel"
local style = require "src.style"

local WaveLite = {}

WaveLite.style_UI = style.new()
WaveLite.style_code = style.new()

WaveLite.project = false

local text = [[

You'll want a symlink AppData/Roaming/LOVE/WaveLite <==> <repo>/data
	Write your computer username between the '<' and '>' <here>
	Click on this line to copy the path to your clipboard and open it

Plugins:
	plugins/core.lua
	plugins/custom.lua

Select one of those and press ctrl-shift-t to open it up
]]

function WaveLite.load()
	local plugin = require "src.lib.plugin"

	plugin.load "core"
	plugin.load "custom"

	-- global configs, settings, reference to main pane handler, etc

	local split = require "src.elements.Divisions" "horizontal"
	local tabs = split:add( require "src.elements.TabManager" () )
	local editor = tabs.api.open( "content", text ).focus()

	split.x = 200
	split.y = 0

	function split:onParentResized()
		self:resize( self.parent.width - self.x, self.parent.height - self.y )
	end

	UIPanel.main:add( split )
end

return WaveLite
