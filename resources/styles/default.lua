
local util = require "lib.util"
local rgb = util.rgb

return {
	Keyword = {
		Loop = {
			_Default = rgb( 0xc53d67 );
		};
		Function = {
			_Default = rgb( 0xc53d67 );
		};
		Declare = {
			_Default = rgb( 0xc53d67 );
		};
		Control = {
			_Default = rgb( 0xc53d67 );
		};
		_Default = rgb( 0xc53d67 );
	},
	Operator = {
		_Default = { 121, 250, 70 };
	},
	Constant = {
		_Default = { 40, 40, 40 };
		Identifier = rgb( 0x404040 );
		Boolean = rgb( 0xed912c );
		Number = rgb( 0x3092c6 );
		String = rgb( 0x3092c6 );
	},
	Operator = {
		_Default = rgb( 0xc53d67 );
	};
	Symbol = {
		_Default = rgb( 0xc53d67 );
	},
	Comment = {
		_Default = rgb( 0x919d9f );
	},

	_Default = rgb( 0x404040 ),
	_Background = rgb( 0xfafafa );
}
	