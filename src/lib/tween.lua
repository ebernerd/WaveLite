
local function default_easing( u, d, t )
	return u + d * (3 - 2 * t) * t * t
end

local function newTween( initial, final, duration, easing )
	local clock = 0
	local diff = final - initial

	easing = easing or default_easing

	return function( dt, f )
		clock = clock + dt

		if f then
			diff = f - initial
		end

		if clock > duration then
			return initial + diff, true
		end

		return easing( initial, diff, clock / duration ), false
	end
end

return newTween
