
local UIPanel = require "src.elements.UIPanel"
local style = require "src.style"
local plugin = require "src.lib.plugin"

local WaveLite = {}

WaveLite.style_UI = style.new()
WaveLite.style_code = style.new()

plugin.load( "core", "resources/plugins/core.lua" )
plugin.load( "custom", "resources/plugins/custom.lua" )

-- global configs, settings, reference to main pane handler, etc

local tabs = require "src.elements.TabManager" ()
local editor = tabs.api.open( "blank" )

tabs.x = 100
tabs.y = 100
tabs:resize( 600, 400 )
editor:focus()

function tabs:onParentResized()
	self:resize( self.parent.width - self.x - 10, self.parent.height - self.y - 10 )
end

UIPanel.main:add( tabs )
