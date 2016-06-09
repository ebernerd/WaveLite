
local formatting = require "src.lib.formatting"

return formatting.newFormatter {
	keywords = {
		["if"] = "syntax:Keyword";
		["else"] = "syntax:Keyword";
		["while"] = "syntax:Keyword";
		["for"] = "syntax:Keyword";
		["foreach"] = "syntax:Keyword";
		["in"] = "syntax:Keyword";
		["repeat"] = "syntax:Keyword";
		["until"] = "syntax:Keyword";
		["switch"] = "syntax:Keyword";
		["case"] = "syntax:Keyword";
		["default"] = "syntax:Keyword";
		["try"] = "syntax:Keyword";
		["catch"] = "syntax:Keyword";
		["class"] = "syntax:Keyword";
		["extends"] = "syntax:Keyword";
		["implements"] = "syntax:Keyword";
		["interface"] = "syntax:Keyword";
		["enum"] = "syntax:Keyword";
		["namespace"] = "syntax:Keyword";
		["using"] = "syntax:Keyword";
		["import"] = "syntax:Keyword";
		["return"] = "syntax:Keyword";
		["break"] = "syntax:Keyword";
		["continue"] = "syntax:Keyword";
		["auto"] = "syntax:Keyword";
		["void"] = "syntax:Keyword";
		["public"] = "syntax:Keyword";
		["private"] = "syntax:Keyword";
		["static"] = "syntax:Keyword";
		["let"] = "syntax:Keyword";
		["const"] = "syntax:Keyword";
		["throw"] = "syntax:Keyword";
		["super"] = "syntax:Keyword";
		["operator"] = "syntax:Keyword";
		["function"] = "syntax:Keyword";
		["new"] = "syntax:Keyword";
		["typeof"] = "syntax:Keyword";
		["final"] = "syntax:Keyword";
		["abstract"] = "syntax:Keyword";
		["and"] = "syntax:Keyword";
		["or"] = "syntax:Keyword";
		["safe"] = "syntax:Keyword";
		["typename"] = "syntax:Keyword";
		
		["true"] = "syntax:Constant.Boolean";
		["false"] = "syntax:Constant.Boolean";
		["null"] = "syntax:Constant.Null";

		["int"] = "syntax:Typename.Native";
		["float"] = "syntax:Typename.Native";
		["string"] = "syntax:Typename.Native";
		["byte"] = "syntax:Typename.Native";
		["char"] = "syntax:Typename.Native";
		["bool"] = "syntax:Typename.Native";
	};

	symbols = {
		["="] = "syntax:Symbol";

		["["] = "syntax:Symbol.Bracket.Square";
		["]"] = "syntax:Symbol.Bracket.Square";
		["("] = "syntax:Symbol.Bracket.Round";
		[")"] = "syntax:Symbol.Bracket.Round";
		["{"] = "syntax:Symbol.Bracket.Curly";
		["}"] = "syntax:Symbol.Bracket.Curly";

		["+"] = "syntax:Operator.Math.Add";
		["-"] = "syntax:Operator.Math.Sub";
		["*"] = "syntax:Operator.Math.Mul";
		["/"] = "syntax:Operator.Math.Div";
		["%"] = "syntax:Operator.Math.Mod";
		["**"] = "syntax:Operator.Math.Pow";

		["+="] = "syntax:Operator.Math.Add";
		["-="] = "syntax:Operator.Math.Sub";
		["*="] = "syntax:Operator.Math.Mul";
		["/="] = "syntax:Operator.Math.Div";
		["%="] = "syntax:Operator.Math.Mod";
		["**="] = "syntax:Operator.Math.Pow";

		["++"] = "syntax:Operator.Math.Add";
		["--"] = "syntax:Operator.Math.Sub";

		["=="] = "syntax:Operator.Compare.Eq";
		["!="] = "syntax:Operator.Compare.Neq";
		[">="] = "syntax:Operator.Compare.Gte";
		["<="] = "syntax:Operator.Compare.Lte";
		[">"] = "syntax:Operator.Compare.Gt";
		["<"] = "syntax:Operator.Compare.Lt";

		["&"] = "syntax:Operator.Bitwise.And";
		["|"] = "syntax:Operator.Bitwise.Or";
		["^"] = "syntax:Operator.Bitwise.Xor";
		["<<"] = "syntax:Operator.Bitwise.Lshift";
		[">>"] = "syntax:Operator.Bitwise.Rshift";

		["&="] = "syntax:Operator.Bitwise.And";
		["|="] = "syntax:Operator.Bitwise.Or";
		["^="] = "syntax:Operator.Bitwise.Xor";
		["<<="] = "syntax:Operator.Bitwise.Lshift";
		[">>="] = "syntax:Operator.Bitwise.Rshift";

		["&&"] = "syntax:Operator.And";
		["||"] = "syntax:Operator.Or";

		["&&="] = "syntax:Operator.And";
		["||="] = "syntax:Operator.Or";

		["!"] = "syntax:Operator.Not";
		["#"] = "syntax:Operator.Len";
		["~"] = "syntax:Operator.Bitwise.Not";

		[".."] = "syntax:Operator.Range";
		["->"] = "syntax:Operator.Cast";

		["@"] = "syntax:Symbol.Preprocessor";

		["..."] = "syntax:Symbol.Vararg";

		["::"] = "syntax:Symbol.Index";
		["."] = "syntax:Symbol.Index";
		[":"] = "syntax:Symbol.Index";

		[","] = "syntax:Symbol.Sep";
		[";"] = "syntax:Symbol.Sep";
	};

	comments = {
		start = {
			line = "//";
			multiline = "/%*";
		};
		finish = {
			line = "$";
			multiline = "%*/";
		};
	};

	strings = {
		start = {
			line = "[\"\']";
			multiline = "[\"\']";
		};
		finish = {
			line = "%1";
			multiline = "%1";
		};
		escape = {
			line = "\\";
			multiline = "\\";
		};
	};
}
