
--[[
	system
		string platform()
		void copy(string text)
		string paste()
]]

local util = require "src.lib.util"

local function newSystemAPI()
	local system = {}

	function system.platform()
		return love.system.getOS()
	end

	function system.copy( text )
		return love.system.setClipboardText( text )
	end

	function system.paste()
		return love.system.getClipboardText()
	end

	function system.show_keyboard()
		if not love.keyboard.hasTextInput() then
			return love.keyboard.setTextInput( true )
		end
	end

	function system.hide_keyboard()
		return love.keyboard.setTextInput( false )
	end

	return util.protected_table( system )
end

return newSystemAPI
