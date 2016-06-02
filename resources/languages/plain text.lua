
local util = require "src.util"

return function( line, state )
	return util.formatText( line )
end
