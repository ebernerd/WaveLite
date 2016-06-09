
local UIPanel = require "src.elements.UIPanel"

local WaveLite = {}

require "resources.plugins.core"
require "resources.plugins.custom"

-- global configs, settings, reference to main pane handler, etc

local editor = require "src.elements.CodeEditor" ()

editor.x = 100
editor.y = 100
editor:resize( 600, 400 )
editor:focus()

function editor:onParentResized()
	self:resize( self.parent.width - self.x - 10, self.parent.height - self.y - 10 )
end

UIPanel.main:add( editor )
