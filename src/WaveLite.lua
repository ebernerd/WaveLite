
local UIPanel = require "src.elements.UIPanel"
local style = require "src.style"

local WaveLite = {}

WaveLite.style_UI = style.new()
WaveLite.style_code = style.new()

require "resources.plugins.core"
require "resources.plugins.custom"

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
