
local event = {}
local events = {}

function event.bind( event, callback )
	events[event] = events[event] or {}
	events[event][#events[event] + 1] = callback
end

function event.unbind( event, callback )
	if events[event] then
		for i = #events[event], 1, -1 do
			if events[event][i] == callback then
				table.remove( events[event], i )
			end
		end
	end
end

function event.invoke( event, ... )
	if events[event] then
		for i = 1, #events[event] do
			local ok, err = pcall( events[event][i], ... )

			if not ok then
				error( err, 0 )
				-- do something?
			end
		end
	end
end

return event
