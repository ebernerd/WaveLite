
local util = require "util"

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

return formatting
