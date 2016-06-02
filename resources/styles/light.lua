
local util = require "src.util"
local rgb = util.rgb

return {
	-- syntax highlighting
	["syntax:Keyword"] = rgb( 0xc53d67 );
	["syntax:Keyword.Loop"] = rgb( 0xc53d67 );
	["syntax:Keyword.Function"] = rgb( 0xc53d67 );
	["syntax:Keyword.Declare"] = rgb( 0xc53d67 );
	["syntax:Keyword.Control"] = rgb( 0xc53d67 );
	["syntax:Operator"] = { 121, 250, 70 };
	["syntax:Constant"] = { 40, 40, 40 };
	["syntax:Constant.Identifier"] = rgb( 0x404040 );
	["syntax:Constant.Boolean"] = rgb( 0xed912c );
	["syntax:Constant.Number"] = rgb( 0x3092c6 );
	["syntax:Constant.String"] = rgb( 0x3092c6 );
	["syntax:Operator"] = rgb( 0xc53d67 );
	["syntax:Symbol"] = rgb( 0xc53d67 );
	["syntax:Comment"] = rgb( 0x919d9f );
	["syntax:default"] = rgb( 0x404040 );

	-- editor settings
	["editor:Foreground"] = rgb( 0x404040 );
	["editor:Background"] = rgb( 0xfafafa );
	["editor:Background.Selected"] = { 80, 160, 255, 64 };
	["editor:Scrollbar.Tray"] = rgb( 0xdddddd );
	["editor:Scrollbar.Slider"] = rgb( 0xbbbbbb );
	["editor:Cursor"] = rgb( 0x303030 );

	["editor:Lines.Background"] = rgb( 0xf0f0f0 );
	["editor:Lines.Foreground"] = rgb( 0x606060 );
	["editor:Lines.Padding"] = 20;
	["editor:Lines.CodePadding"] = 5;

	["editor:Font"] = love.graphics.newFont( "resources/fonts/Hack.ttf", 15 );

	default = rgb( 0xffffff );
}
