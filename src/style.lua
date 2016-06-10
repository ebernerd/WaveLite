
local libconfig = require "src.lib.config"
local rgb = require "src.lib.util" .rgb

local template = {
	["syntax"] = nil;
		["syntax:Keyword"] = rgb( 0xc53d67 );

		["syntax:Operator"] = rgb( 0xc53d67 );
			["syntax:Operator.Math.Add"] = nil;
			["syntax:Operator.Math.Sub"] = nil;
			["syntax:Operator.Math.Mul"] = nil;
			["syntax:Operator.Math.Div"] = nil;
			["syntax:Operator.Math.Mod"] = nil;
			["syntax:Operator.Math.Pow"] = nil;
				["syntax:Operator.Math.Unary.Minus"] = nil;

			["syntax:Operator.Bitwise.And"] = nil;
			["syntax:Operator.Bitwise.Or"] = nil;
			["syntax:Operator.Bitwise.Xor"] = nil;
			["syntax:Operator.Bitwise.Lshift"] = nil;
			["syntax:Operator.Bitwise.Rshift"] = nil;
				["syntax:Operator.Bitwise.Unary.Bnot"] = nil;

			["syntax:Operator.Comparison.Eq"] = nil;
			["syntax:Operator.Comparison.Neq"] = nil;
			["syntax:Operator.Comparison.Lt"] = nil;
			["syntax:Operator.Comparison.Gt"] = nil;
			["syntax:Operator.Comparison.Lte"] = nil;
			["syntax:Operator.Comparison.Gte"] = nil;

			["syntax:Operator.Logic.And"] = nil;
			["syntax:Operator.Logic.Or"] = nil;
				["syntax:Operator.Logic.Unary.Not"] = nil;

			["syntax:Operator.Unary.Len"] = nil;

		["syntax:Constant"] = rgb( 0x1070a0 );
			["syntax:Constant.String"] = rgb( 0x1070a0 );
			["syntax:Constant.Number"] = rgb( 0x1070a0 );
				["syntax:Constant.Number.Integer"] = nil;
			["syntax:Constant.Boolean"] = rgb( 0xed912c );
			["syntax:Constant.Character"] = nil;
			["syntax:Constant.Null"] = nil;
			["syntax:Constant.Identifier"] = rgb( 0x404040 );

		["syntax:Library"] = rgb( 0x3092c6 );
			["syntax:Library.Native"] = rgb( 0x3092c6 );
			["syntax:Library.User"] = rgb( 0x3092c6 );

		["syntax:Comment"] = rgb( 0x919d9f );
		["syntax:Typename"] = rgb( 0x80a0e0 );
		["syntax:default"] = rgb( 0x404040 );

	-- editor settings
	["editor"] = nil;
		["editor:Outline"] = nil;
			["editor:Outline.Foreground"] = rgb( 0x404040 );
			["editor:Outline.Shown"] = true;

		["editor:Code"] = nil;
			["editor:Code.Background"] = rgb( 0xfafafa );
				["editor:Code.Background.Selected"] = { 80, 160, 255, 40 };
			["editor:Code.Foreground"] = rgb( 0x404040 );
			["editor:Code.Padding"] = 10;

		["editor:Tabs"] = nil;
			["editor:Tabs.Width"] = 4;
			["editor:Tabs.Foreground"] = rgb( 0xd0d0d0 );
			["editor:Tabs.Shown"] = true;

		["editor:Lines"] = nil;
			["editor:Lines.Background"] = rgb( 0xf5f5f5 );
			["editor:Lines.Foreground"] = rgb( 0xb0b0b0 );
			["editor:Lines.Shown"] = true;
			["editor:Lines.Padding"] = 20;

		["editor:Scrollbar"] = nil;
			["editor:Scrollbar.Tray"] = rgb( 0xdddddd );
			["editor:Scrollbar.Slider"] = rgb( 0xbbbbbb );

		["editor:Cursor"] = nil;
			["editor:Cursor.Foreground"] = rgb( 0x303030 );
			["editor:Cursor.FullCharWidth"] = false;

		["editor:Font"] = love.graphics.newFont( "resources/fonts/Inconsolata/Inconsolata.otf", 16 );

	["Tabs"] = nil;
		["Tabs:Background"] = rgb( 0xf0f0f0 );
		["Tabs:Foreground"] = { 0, 0, 0, 150 };
		["Tabs:Padding"] = 32;
		["Tabs:Divider"] = { 0, 0, 0, 20 };
		["Tabs:Selected"] = { 100, 180, 255 };
		["Tabs:Expand"] = true;
		["Tabs:Font"] = love.graphics.newFont( "resources/fonts/Exo.otf", 17 );
}

local function get( value )
	while type( value ) == "string" and value:sub( 1, 1 ) == "@" do
		value = libconfig:get( value:sub( 2 ) )
	end
	return value
end

local style = {}

function style.new( t )
	return t or {}
end

function style:set( index, value )
	self[index] = value
end

function style:get( rawindex )
	local parts = {}
	local i = 1
	local index

	for part in rawindex:gmatch "[^%.]+" do
		parts[i] = part
		i = i + 1
	end

	for i = #parts, 1, -1 do
		index = table.concat( parts, ".", 1, i )

		if self[index] ~= nil then
			break
		else
			index = nil
		end
	end

	if not index and template ~= self then
		local v, i = style.get( template, rawindex )
		if v and i:sub( -7 ) ~= "default" then
			return v
		end
	end

	if not index and parts[1]:find ":" then
		index = parts[1]:gsub( ":.-$", ":default" )

		if self[index] == nil then
			if template[index] ~= nil then
				return get( template[index] ), index
			else
				return get( template.default ), "default"
			end
		end
	end

	return get( self[index] ), index
end

return style
