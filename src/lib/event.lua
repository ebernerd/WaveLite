
local log = require "src.lib.log"

local event = {}
local events = {}

function event.bind( event, callback, binder )
	local conditions = {}

	if event:find "#" then
		for part in (event:match ".-#(.+)$" or ""):gmatch "[^;#]+" do
			conditions[part:match "^%s*(%S+)%s*=" or part] = part:match "^%s*%S+%s*=%s*(.*)%s*$" or true
		end

		event = event:match "^(.-)%s*#"
	end

	events[event] = events[event] or {}
	events[event][#events[event] + 1] = { callback = callback, conditions = conditions, binder = binder }
end

function event.unbind( event, callback, binder )
	if events[event] then
		for i = #events[event], 1, -1 do
			if events[event][i].callback == callback and (not binder or events[event][i].binder == binder) then
				table.remove( events[event], i )
			end
		end
	end
end

function event.unbind_binder( binder, ename )
	if ename then
		for i = #events[ename], 1, -1 do
			if events[ename][i].binder == binder then
				table.remove( events[ename], i )
			end
		end
	else
		for k, v in pairs( events ) do
			event.unbind_binder( binder, k )
		end
	end
end

function event.invoke( event, param, ... )
	local etocall = {}

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
				etocall[#etocall + 1] = events[event][i].callback
			end
		end
	end

	for i = 1, #etocall do
		local ok, err = pcall( etocall[i], param, ... )

		if not ok then
			log( err )
		end
	end
end

return event
