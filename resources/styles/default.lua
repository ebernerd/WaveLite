
local util = require "src.util"
local rgb = util.rgb

return {
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

	--[[_Default = rgb( 0x404040 );
	_Foreground = rgb( 0x404040 );
	_Background = rgb( 0xfafafa );
	_BackgroundSelected = rgb( 0xa0b0f0 );
	_ForegroundSelected = rgb( 0xffffff );
	_ScrollbarTray = rgb( 0xdddddd );
	_ScrollbarSlider = rgb( 0xcccccc );]]
}
