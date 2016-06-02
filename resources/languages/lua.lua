
local formatting = require "src.formatting"

return formatting.newFormatter {
	keywords = {
		["if"] = "syntax:Keyword.Control.If";
		["else"] = "syntax:Keyword.Control.Else";
		["elseif"] = "syntax:Keyword.Control.Elseif";

		["repeat"] = "syntax:Keyword.Loop.Repeat";
		["while"] = "syntax:Keyword.Loop.While";

		["for"] = "syntax:Keyword.Loop.For";
		["in"] = "syntax:Keyword";

		["and"] = "syntax:Operator.And";
		["or"] = "syntax:Operator.Or";
		["not"] = "syntax:Operator.Not";

		["break"] = "syntax:Keyword.Control.Break";
		["return"] = "syntax:Keyword.Control.Return";

		["do"] = "syntax:Keyword";
		["then"] = "syntax:Keyword";
		["until"] = "syntax:Keyword";
		["end"] = "syntax:Keyword.Control";

		["function"] = "syntax:Keyword.Function";

		["local"] = "syntax:Keyword.Declare";

		["true"] = "syntax:Constant.Boolean";
		["false"] = "syntax:Constant.Boolean";
		["nil"] = "syntax:Constant.Null";
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
		["^"] = "syntax:Operator.Math.Pow";

		["=="] = "syntax:Operator.Compare.Eq";
		["~="] = "syntax:Operator.Compare.Neq";
		[">="] = "syntax:Operator.Compare.Gte";
		["<="] = "syntax:Operator.Compare.Lte";
		[">"] = "syntax:Operator.Compare.Gt";
		["<"] = "syntax:Operator.Compare.Lt";

		["#"] = "syntax:Operator.Len";

		["."] = "syntax:Symbol.Index";
		[":"] = "syntax:Symbol.Index";

		[","] = "syntax:Symbol.Sep";
		[";"] = "syntax:Symbol.Sep";
	};

	comments = {
		start = {
			line = "%-%-";
			multiline = "%-%-%[(=*)%[";
		};
		finish = {
			line = "$";
			multiline = "%]%1%]";
		};
	};

	strings = {
		start = {
			line = "[\"\']";
			multiline = "%[(=*)%[";
		};
		finish = {
			line = "%1";
			multiline = "%]%1%]";
		};
		escape = {
			line = "\\";
			multiline = nil;
		};
	};
}
