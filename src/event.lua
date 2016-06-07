
local event = {}
local events = {}

function event.bind( event, callback )
	local conditions = {}

	if event:find "#" then
		for part in event:match ".+#(.*)$":gmatch "[^;]" do
			conditions[part:match "(.+)%s*=" or part] = part:match ".+%s*=%s*(.*)$" or true
		end

		event = event:match ".+#"
	end

	events[event] = events[event] or {}
	events[event][#events[event] + 1] = { callback = callback, conditions = conditions }
end

function event.unbind( event, callback )
	if events[event] then
		for i = #events[event], 1, -1 do
			if events[event][i].callback == callback then
				table.remove( events[event], i )
			end
		end
	end
end

function event.invoke( event, param, ... )
	if events[event] then
		for i = 1, #events[event] do
			local cancall = true

			if type( param ) == "table" then
				for k, v in pairs( events[event][i].conditions ) do
					if type( param[k] ) == "function" and param[k]( param ) ~= v then
						cancall = false
						break
					end
				end
			end

			if cancall then
				local ok, err = pcall( events[event][i].callback, param, ... )

				if not ok then
					error( err, 0 )
					-- do something?
				end
			end
		end
	end
end

return event
