
local util = require "src.util"
local rgb = util.rgb

return {
	-- syntax highlighting
	["Keyword"] = rgb( 0xc53d67 );
	["Keyword.Loop"] = rgb( 0xc53d67 );
	["Keyword.Function"] = rgb( 0xc53d67 );
	["Keyword.Declare"] = rgb( 0xc53d67 );
	["Keyword.Control"] = rgb( 0xc53d67 );
	["Operator"] = { 121, 250, 70 };
	["Constant"] = { 40, 40, 40 };
	["Constant.Identifier"] = rgb( 0x404040 );
	["Constant.Boolean"] = rgb( 0xed912c );
	["Constant.Number"] = rgb( 0x3092c6 );
	["Constant.String"] = rgb( 0x3092c6 );
	["Operator"] = rgb( 0xc53d67 );
	["Symbol"] = rgb( 0xc53d67 );
	["Comment"] = rgb( 0x919d9f );
	["default"] = rgb( 0x404040 );

	-- editor settings
	["Foreground"] = rgb( 0x404040 );
	["Background"] = rgb( 0xfafafa );
	["Background.Selected"] = { 80, 160, 255, 40 };
	["Scrollbar.Tray"] = rgb( 0xdddddd );
	["Scrollbar.Slider"] = rgb( 0xbbbbbb );

	["font"] = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 );
}
