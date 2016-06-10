
local WaveLite = require "src.WaveLite"
local UIPanel = require "src.elements.UIPanel"
local libstyle = require "src.style"
local rendering = require "src.lib.rendering"
local newTabManagerAPI = require "src.lib.apis.tabmanager"
local tween = require "src.lib.tween"

local TABPADDING = 5
local TRANSITION_TIME = 0.2
local _finished

local function recalcwidths( tabs )
	local font = libstyle.get( WaveLite.style_UI, "Tabs:Font" )
	local fHeight = font:getHeight()
	local padding = libstyle.get( WaveLite.style_UI, "Tabs:Padding" )
	local total = 0

	for i = 1, #tabs.editors do
		tabs.tabwidths[i] = font:getWidth( tabs.editors[i].title ) + 2 * padding
		total = total + tabs.tabwidths[i]
	end

	if total < tabs.width then
		local diff = (tabs.width - total) / #tabs.editors

		for i = 1, #tabs.editors do
			tabs.tabwidths[i] = tabs.tabwidths[i] + diff
		end
	end
end

local function newTabManager()

	local tabs = UIPanel.new()

	tabs.scrollX = 0
	tabs.api = newTabManagerAPI( tabs )
	tabs.visibleTab = false
	tabs.tabwidths = {}
	tabs.display = tabs:add( UIPanel.new() )
	tabs.editors = {}
	tabs.selected_left = 0
	tabs.selected_size = 0
	tabs.selected_left_tween = nil
	tabs.selected_size_tween = nil
	tabs.toIndex = 0
	tabs.touch = false

	function tabs.display:onTouch( x, y, button )
		tabs.touch = { x = x + tabs.scrollX, y = y, button = button, moved = false }
	end

	function tabs.display:onMove( x, y, button )
		if tabs.touch then
			local diff = tabs.touch.x - x - tabs.scrollX
			local totalwidth = 0

			for i = 1, #tabs.tabwidths do
				totalwidth = totalwidth + tabs.tabwidths[i]
			end

			if tabs.touch.moved or math.abs( diff ) > 4 then
				tabs.touch.moved = true
				tabs.scrollX = math.max( 0, math.min( tabs.scrollX + diff, totalwidth - self.width ) )
			end
		end
	end

	function tabs.display:onRelease( x, y, button )
		if tabs.touch then
			if not tabs.touch.moved then
				local totalwidth = 0
				local x = x + tabs.scrollX

				for i = 1, #tabs.tabwidths do
					totalwidth = totalwidth + tabs.tabwidths[i]

					if totalwidth > x then
						tabs:switchTo( tabs.editors[i] )
						break
					end
				end
			end

			tabs.touch = false
		end
	end

	function tabs:addEditor( editor )
		tabs.editors[#tabs.editors + 1] = editor

		editor.y = tabs.display.height
		editor.width = self.width
		editor.height = self.height - tabs.display.height

		if self.visibleTab then
			self.visibleTab.visible = false
			self.visibleTab = editor
		end

		recalcwidths( self )
		self:switchTo( editor )

		return self:add( editor )
	end

	function tabs:removeEditor( editor )
		for i = #self.editors, 1, -1 do
			if self.editors[i] == editor then
				table.remove( self.editors, i )
			end
		end

		recalcwidths( self )

		return self:remove( editor )
	end

	function tabs:switchTo( editor )
		local w = 0

		if self.visibleTab ~= false then
			self.visibleTab.visible = false
		end

		editor.visible = true
		self.visibleTab = editor
		editor:focus()

		for i = 1, #self.editors do
			if self.editors[i] == editor then
				self.selected_size_tween = tween( self.selected_size, self.tabwidths[i], TRANSITION_TIME )
				self.toIndex = i
				break
			else
				w = w + self.tabwidths[i]
			end
		end

		self.selected_left_tween = tween( self.selected_left, w, TRANSITION_TIME )
	end

	function tabs:resize( w, h )
		if w ~= self.width or h ~= self.height then
			self.width, self.height = w, h
		
			recalcwidths( self )

			for i = 1, #self.editors do
				self.editors[i]:resize( self.width, self.height - tabs.display.height )
				self.editors[i]:onParentResized( self )
			end
		end
	end

	function tabs.display:onDraw( stage )
		if stage == "before" then
			rendering.tabs( tabs )
		end
	end

	function tabs:onUpdate( dt )
		local font = libstyle.get( WaveLite.style_UI, "Tabs:Font" )
		local fHeight = font:getHeight()

		tabs.display.width = self.width
		tabs.display.height = fHeight + 2 * TABPADDING

		for i = 1, #self.editors do
			self.editors[i].y = tabs.display.height
			self.editors[i]:resize( self.width, self.height - tabs.display.height )
		end

		recalcwidths( self )

		if tabs.selected_left_tween then
			local total = 0

			for i = 1, self.toIndex - 1 do
				total = total + self.tabwidths[i]
			end

			tabs.selected_left, _finished = tabs.selected_left_tween( dt, total )

			if _finished then
				tabs.selected_left_tween = nil
			end
		end

		if tabs.selected_size_tween then
			tabs.selected_size, _finished = tabs.selected_size_tween( dt, self.tabwidths[self.toIndex] )

			if _finished then
				tabs.selected_size_tween = nil
			end
		end
	end

	return tabs

end

return newTabManager
