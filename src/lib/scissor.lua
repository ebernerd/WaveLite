
local stack = {}
local current = {}
local scissor = {}

local function bbox( a, b, c, d, A, B, C, D )
	local x = math.max( a, A )
	local y = math.max( b, B )
	local w = math.min( a + c, A + C ) - x
	local h = math.min( b + d, B + D ) - y

	return w > 0 and h > 0 and {x, y, w, h} or false
end

function scissor.push( x, y, width, height )
	stack[#stack + 1] = stack[1] == nil and { x, y, width, height } or stack[#stack] and bbox( x, y, width, height, unpack( stack[#stack] ) ) or false

	if stack[#stack] then
		print( unpack( stack[#stack] ) )
		love.graphics.setScissor( unpack( stack[#stack] ) )
	else
		love.graphics.setScissor( 0, 0, 0, 0 )
	end
end

function scissor.pop()
	stack[#stack] = nil

	if stack[1] == nil then
		love.graphics.setScissor()
	elseif stack[#stack] then
		love.graphics.setScissor( unpack( stack[#stack] ) )
	else
		love.graphics.setScissor( 0, 0, 0, 0 )
	end
end

return scissor
