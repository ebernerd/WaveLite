
local UIPanel = require "src.elements.UIPanel"
local style = require "src.style"
local divisions = require "src.elements.Divisions"

local WaveLite = {}

WaveLite.style_UI = style.new()
WaveLite.style_code = style.new()

WaveLite.project = false
WaveLite.editors = {}
WaveLite.tab_managers = {}

local function getMode( dir )
	return (dir == "up" or dir == "down") and "vertical" or "horizontal"
end

local function isNewFirst( dir )
	return dir == "up" or dir == "left"
end

local text = [[

You'll want a symlink AppData/Roaming/LOVE/WaveLite <==> <repo>/data
	Write your computer username between the '<' and '>' <here>
	Alt-click on this line to copy the path to your clipboard and open it

Plugins (alt-click to open):
	open 'plugins/core.lua' [core:lua]
	open 'plugins/custom.lua' [core:lua]
	open 'user/projects/MyProject/src/main.lua' [core:flux]

Select one of those and press ctrl-shift-t to open it up
]]

function WaveLite.load()
	local plugin = require "src.lib.plugin"
	local CodeEditor = require "src.elements.CodeEditor"

	plugin.load "core"
	plugin.load "custom"

	-- global configs, settings, reference to main pane handler, etc

	local split = require "src.elements.Divisions" "horizontal"
	local tabs = split:add( require "src.elements.TabManager" () )
	local editor = CodeEditor( "content", "untitled", text )

	tabs:addEditor( editor )
	editor.api.focus()

	split.x = 200
	split.y = 0

	WaveLite.tab_managers[1] = tabs
	WaveLite.editors[1] = editor

	function split:onParentResized()
		self:resize( self.parent.width - self.x, self.parent.height - self.y )
	end

	UIPanel.main:add( split )
end

function WaveLite.splitTab( tabs, adding, direction )
	local div = tabs.parent

	if div.direction ~= getMode( direction ) then
		local d = divisions( getMode( direction ) )

		div:replaceChild( tabs, d )
		d:add( isNewFirst( direction ) and adding or tabs )
		d:add( isNewFirst( direction ) and tabs or adding )
	else
		div:add( adding, isNewFirst( direction ) and tabs or div:nextChild( tabs ) )
	end

	WaveLite.tab_managers[#WaveLite.tab_managers + 1] = adding

	return adding
end

function WaveLite.splitEditor( editor, adding, direction )
	local div = editor.parent

	if div.direction ~= getMode( direction ) then
		local d = divisions( getMode( direction ) )
		
		div:replaceChild( editor, d )
		d:add( isNewFirst( direction ) and adding or editor )
		d:add( isNewFirst( direction ) and editor or adding )
	else
		div:add( adding, isNewFirst( direction ) and editor or div:nextChild( editor ) )
	end
	
	WaveLite.editors[#WaveLite.editors + 1] = adding

	return adding
end

function WaveLite.closeTab( child )
	local div = child.parent

	div:remove( child )

	while div.parent and #div.children == 0 and div ~= UIPanel.body do
		local parent = div.parent
		parent:remove( div )
		div = parent
	end
end

function WaveLite.closeEditor( child )
	local div = child.parent

	if div.type == "tabs" then
		div:removeEditor( child )
	else
		div:remove( child )
	end

	while div.parent and (#div.children == 0 or #div.children == 1 and div.type == "tabs") and div ~= UIPanel.body do
		local parent = div.parent
		parent:remove( div )
		div = parent
	end
end

return WaveLite
