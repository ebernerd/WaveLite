
local style = require "src.style"
local rgb = require "src.lib.util" .rgb

return style.new {
	["syntax:Keyword"] = rgb( 0xff70c0 ); -- 0xf06aa0
	["syntax:Constant"] = rgb( 0x50baff );
	["syntax:Constant.Boolean"] = rgb( 0xd0d070 );
	["syntax:Constant.Number"] = rgb( 0x50baff );
	["syntax:Constant.String"] = rgb( 0x50baff );
	["syntax:Constant.Identifier"] = rgb( 0xeaeaea );
	["syntax:Operator"] = rgb( 0xf070a0 );
	["syntax:Comment"] = rgb( 0x90a0a0 );
	["syntax:Typename"] = rgb( 0x60e0f0 );
	["syntax:default"] = rgb( 0xd0d0d0 );

	-- editor settings
	["editor:Code.Foreground"] = rgb( 0xe0e0e0 );
	["editor:Code.Background"] = rgb( 0x3a3a3a );
	["editor:Code.Background.Selected"] = { 80, 160, 255, 64 };
	["editor:Scrollbar.Tray"] = rgb( 0x333333 );
	["editor:Scrollbar.Slider"] = rgb( 0x666666 );
	["editor:Cursor.Foreground"] = rgb( 0xb0b0b0 );

	["editor:Outline.Foreground"] = rgb( 0xd0d0d0 );
	["editor:Tabs.Foreground"] = rgb( 0x505050 );

	["editor:Lines.Background"] = rgb( 0x505050 );
	["editor:Lines.Foreground"] = rgb( 0xb0b0b0 );
}
