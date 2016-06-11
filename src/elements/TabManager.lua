
local WaveLite = require "src.WaveLite"
local UIPanel = require "src.elements.UIPanel"
local libstyle = require "src.style"
local rendering = require "src.lib.rendering"
local newTabManagerAPI = require "src.lib.apis.tabmanager"
local tween = require "src.lib.tween"
local util = require "src.lib.util"

local TABPADDING = 5
local TRANSITION_TIME = 0.3
local SCROLLSPEED = 35
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

	tabs.type = "tabs"
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
	tabs.scroll_tween = nil
	tabs.scroll_target = 0
	tabs.toIndex = 0
	tabs.display.enable_keyboard = true
	tabs.enable_keyboard = true
	tabs.tweening = false

	function tabs.display:onTouch( x )
		self.mount = tabs.scrollX + x
	end

	function tabs.display:onMove( x, y, button )
		if self.touches[button] then
			local totalwidth = 0

			for i = 1, #tabs.tabwidths do
				totalwidth = totalwidth + tabs.tabwidths[i]
			end

			if self.touches[button].moved then
				tabs.scrollX = math.floor( math.max( 0, math.min( self.mount - x, totalwidth - self.width ) ) )
			end
		end
	end

	function tabs.display:onRelease( x, y, button )
		if self.touches[button] then
			if not self.touches[button].moved then
				local totalwidth = 0
				local x = x + tabs.scrollX

				for i = 1, #tabs.tabwidths do
					totalwidth = totalwidth + tabs.tabwidths[i]

					if totalwidth > x then
						if tabs.editors[i] then
							tabs:switchTo( tabs.editors[i] )
						end

						break
					end
				end
			end
		end
	end

	function tabs.display:onWheelMoved( x, y, button )
		local v = x == 0 and y or y == 0 and x or math.sqrt( x * x + y * y ) * math.abs(y) / y * math.abs(x) / x
		local totalwidth = 0

		for i = 1, #tabs.tabwidths do
			totalwidth = totalwidth + tabs.tabwidths[i]
		end

		tabs.scrollX = math.floor( math.max( 0, math.min( tabs.scrollX - v * SCROLLSPEED, totalwidth - self.width ) ) )
	end

	function tabs.display:onUpdate( dt )
		local totalwidth = 0

		for i = 1, #tabs.tabwidths do
			totalwidth = totalwidth + tabs.tabwidths[i]
		end

		local v = math.floor( math.max( 0, math.min( tabs.scrollX, totalwidth - self.width ) ) )

		if v ~= tabs.scrollX and (not tabs.scroll_tween or v ~= tabs.scroll_target) then
			tabs.scroll_tween = tween( tabs.scrollX, v, TRANSITION_TIME )
			tabs.scroll_target = v
		end
		
		if v ~= tabs.scrollX then
			tabs.scrollX, _finished = tabs.scroll_tween( dt, v )

			if _finished then
				tabs.scroll_tween = nil
			end
		end
	end

	function tabs.display:onDraw( stage )
		if stage == "before" then
			rendering.tabs( tabs )
		end
	end

	function tabs.display:onKeypress( key )
		if key == "t" and util.isCtrlHeld() and not util.isShiftHeld() and not util.isAltHeld() then
			tabs.api.open "content" .focus()
		end
	end

	function tabs:addEditor( editor )
		WaveLite.editors[#WaveLite.editors + 1] = editor

		tabs.editors[#tabs.editors + 1] = editor

		editor.y = tabs.display.height
		editor.width = self.width
		editor.height = self.height - tabs.display.height
		editor.visible = false

		recalcwidths( self )

		if #self.editors == 1 then
			local w = 0

			if self.visibleTab then
				self.visibleTab.visible = false
			end

			editor.visible = true
			self.visibleTab = editor

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

		return self:add( editor ).api
	end

	function tabs:removeEditor( editor )
		for i = #self.editors, 1, -1 do
			if self.editors[i] == editor then
				table.remove( self.editors, i )
				table.remove( self.tabwidths, i )

				if i == self.toIndex then
					if self.editors[i] then
						self:switchTo( self.editors[i] )
					elseif self.editors[i - 1] then
						self:switchTo( self.editors[i - 1] )
					end
				end
			end
		end

		recalcwidths( self )

		if #self.editors == 0 then
			self.parent:remove( self )
		end

		return self:remove( editor )
	end

	function tabs:switchTo( editor )
		local w = 0

		if self.visibleTab then
			self.visibleTab.visible = false
		end

		editor.visible = true
		editor:focus()
		self.visibleTab = editor

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

		tabs.tweening = false

		if tabs.selected_left_tween then
			local total = 0

			for i = 1, self.toIndex - 1 do
				total = total + self.tabwidths[i]
			end

			tabs.selected_left, _finished = tabs.selected_left_tween( dt, total )

			if _finished then
				tabs.selected_left_tween = nil
			end

			tabs.tweening = true
		end

		if tabs.selected_size_tween then
			tabs.selected_size, _finished = tabs.selected_size_tween( dt, self.tabwidths[self.toIndex] )

			if _finished then
				tabs.selected_size_tween = nil
			end

			tabs.tweening = true
		end

		if tabs.tweening then
			if tabs.selected_left < tabs.scrollX then
				tabs.scrollX = tabs.selected_left
			elseif tabs.selected_left + tabs.selected_size > tabs.scrollX + tabs.width then
				tabs.scrollX = tabs.selected_left + tabs.selected_size - tabs.width
			end
		end
	end

	function tabs:onKeypress( key )
		if key == "t" and util.isCtrlHeld() and not util.isShiftHeld() and not util.isAltHeld() then
			tabs.api.open "content" .focus()
		end
	end

	return tabs

end

return newTabManager
