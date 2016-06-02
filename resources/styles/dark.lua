
local util = require "src.util"
local rgb = util.rgb

return {
	["syntax:Keyword"] = rgb( 0xf06090 );
	["syntax:Operator"] = { 120, 250, 70 };
	["syntax:Constant.Boolean"] = rgb( 0xed912c );
	["syntax:Constant.Number"] = rgb( 0x30a0d0 );
	["syntax:Constant.String"] = rgb( 0x40b0e0 );
	["syntax:Operator"] = rgb( 0xf06090 );
	["syntax:Symbol"] = rgb( 0xf06090 );
	["syntax:Comment"] = rgb( 0x90a0a0 );
	["syntax:default"] = rgb( 0xe0e0e0 );

	-- editor settings
	["editor:Foreground"] = rgb( 0xe0e0e0 );
	["editor:Background"] = rgb( 0x444444 );
	["editor:Background.Selected"] = { 80, 160, 255, 64 };
	["editor:Scrollbar.Tray"] = rgb( 0x333333 );
	["editor:Scrollbar.Slider"] = rgb( 0x666666 );
	["editor:Cursor"] = rgb( 0xb0b0b0 );

	["editor:Lines.Background"] = rgb( 0x505050 );
	["editor:Lines.Foreground"] = rgb( 0xb0b0b0 );
	["editor:Lines.Padding"] = 20;
	["editor:Lines.CodePadding"] = 5;

	["editor:Font"] = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 );

	default = rgb( 0xffffff );
}
