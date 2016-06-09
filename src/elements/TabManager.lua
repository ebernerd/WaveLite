
local UIPanel = require "src.elements.UIPanel"
local rendering = require "src.lib.rendering"
local newTabManagerAPI = require "src.lib.apis.tabmanager"

local TABDISPLAYHEIGHT = 32

local function newTabManager()

	local tabs = UIPanel.new()

	tabs.scrollX = 0
	tabs.api = newTabManagerAPI( tabs )
	tabs.visibleTab = false

	function tabs:addEditor( editor )
		editor.y = TABDISPLAYHEIGHT
		editor.width = self.width
		editor.height = self.height - TABDISPLAYHEIGHT

		if self.visibleTab then
			self.visibleTab.visible = false
			self.visibleTab = editor
		end

		return self:add( editor )
	end

	function tabs:resize( w, h )
		if w ~= self.width or h ~= self.height then
			self.width, self.height = w, h

			for i = 1, #self.children do
				self.children[i]:resize( self.width, self.height - TABDISPLAYHEIGHT )
				self.children[i]:onParentResized( self )
			end
		end
	end

	function tabs:onDraw( stage )
		if stage == "before" then
			rendering.tabs( self )

			love.graphics.setColor( 0, 0, 0 )
			love.graphics.rectangle( "fill", 0, 0, self.width, TABDISPLAYHEIGHT )
		end
	end

	return tabs

end

return newTabManager
