
local util = require "src.util"

local formatting = {}

function formatting.format( lines, formatting, start, finish )

	local flines = formatting.lines
	local formatter = formatting.formatter
	local states, state = formatting.states

	finish = finish or start or #lines
	start = start or 1

	while start <= finish and start <= #lines do
		state = util.copyt(states[start - 1] or formatting.initial_state)
		flines[start] = formatter( lines[start], state )

		if not util.compare( state, states[start] ) and start == finish then
			finish = finish + 1
		end

		states[start] = state
		start = start + 1
	end

end

function formatting.parse( text )

	local i = 1
	local blocks = {}
	local stack = { { text = "", style = "default" } }
	local escaped = false

	while i <= #text do
		if not escaped and text:sub( i, i ) == "\\" then
			escaped = true
			i = i + 1
		elseif not escaped and text:sub( i, i ) == "{" then
			local style = text:match( "^(%w[%.%w]+):", i + 1 )
			if style then
				blocks[#blocks + 1] = { text = stack[#stack].text, style = stack[#stack].style }
				stack[#stack + 1] = { text = "", style = style }
				i = i + #style + 2
			else
				stack[#stack].text = stack[#stack].text .. text:sub( i, i )
				i = i + 1
			end
		elseif not escaped and text:sub( i, i ) == "}" then
			blocks[#blocks + 1] = { text = stack[#stack].text, style = stack[#stack].style }
			stack[#stack] = nil
			i = i + 1
		else
			escaped = false
			stack[#stack].text = stack[#stack].text .. text:sub( i, i )
			i = i + 1
		end
	end
	
	blocks[#blocks + 1] = stack[#stack]

	return blocks

end

return formatting
