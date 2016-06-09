
local util = require "src.lib.util"

return function( line, state )
	return util.formatText( line )
end
