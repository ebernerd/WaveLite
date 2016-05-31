
local util = require "lib.util"

local function newLanguageFormatter(lang)
	return function(state, line)

		local i = 1
		local res = ""

		if state.in_section then
			local index = state.in_section:match "_(.+)"
			local sindex = (state.in_section == "comment_line" or state.in_section == "comment_multiline") and "comments" or "strings"
			local ending = util.findEndingMatch( line, state.string_match, lang[sindex].finish[index], lang[sindex].escape and lang[sindex].escape[index], 1 )

			if ending then
				state.in_section = false
				i = ending + 1
				res = (sindex == "strings" and "{Constant.String:" or "{Comment:") .. util.formatText( line:sub( 1, ending ) ) .. "}"
			else
				return (sindex == "strings" and "{Constant.String:" or "{Comment:") .. util.formatText( line ) .. "}"
			end
		end

		while i <= #line do
			local pat, fullindex = util.longestOf( line, i,
				lang.strings.start.line, lang.strings.start.multiline,
				lang.comments.start.line, lang.comments.start.multiline,
				"string_line", "string_multiline",
				"comment_line", "comment_multiline"
			)

			if pat then
				local index = fullindex:match "_(.+)"
				local sindex = (fullindex == "string_line" or fullindex == "string_multiline") and "strings" or "comments"
				local ending = util.findEndingMatch( line, pat, lang[sindex].finish[index], lang[sindex].escape and lang[sindex].escape[index], i + #pat )

				if ending then
					res = res .. (sindex == "strings" and "{Constant.String:" or "{Comment:") .. util.formatText( line:sub( i, ending ) ) .. "}"
					i = ending + 1
				else
					state.in_section = fullindex
					state.string_match = pat
					res = res .. (sindex == "strings" and "{Constant.String:" or "{Comment:") .. util.formatText( line:sub( i ) ) .. "}"
					return res
				end

			elseif line:find( "^%d*%.?%d", i ) then
				local match = line:match( "^%d*%.?%d+e[%+%-]%d+", i ) or line:match( "^%d*%.?%d+", i )
				res = res .. "{Constant.Number:" .. match .. "}"
				i = i + #match

			elseif line:find( "^0x%x", i ) then
				local match = line:match( "^0x%x+", i )
				res = res .. "{Constant.Number:" .. match .. "}"
				i = i + #match

			elseif line:find( "^[%w_]", i ) then
				local match = line:match( "^[%w_]+", i )

				if lang.keywords[match] then
					res = res .. "{" .. lang.keywords[match] .. ":" .. match .. "}"
				else
					res = res .. "{Constant.Identifier:" .. match .. "}"
				end
				i = i + #match

			else
				local l, v = 0
				for k, sv in pairs( lang.symbols ) do
					if line:sub( i, i + #k - 1 ) == k then
						if #k > l then
							l = #k
							v = sv
						end
					end
				end

				if l > 0 then
					res = res .. "{" .. v .. ":" .. util.formatText( line:sub( i, i + l - 1 ) ) .. "}"
					i = i + l
				else
					res = res .. util.formatText( line:sub( i, i ) )
					i = i + 1
				end
			end
		end

		return res

	end, {
		in_section = false;
		string_match = "";
	}
end

return newLanguageFormatter
