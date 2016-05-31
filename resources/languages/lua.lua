
return {
	keywords = {
		["if"] = "Keyword.Control.If";
		["else"] = "Keyword.Control.Else";
		["elseif"] = "Keyword.Control.Elseif";

		["repeat"] = "Keyword.Loop.Repeat";
		["while"] = "Keyword.Loop.While";

		["for"] = "Keyword.Loop.For";
		["in"] = "Keyword";

		["and"] = "Operator.And";
		["or"] = "Operator.Or";
		["not"] = "Operator.Not";

		["break"] = "Keyword.Control.Break";
		["return"] = "Keyword.Control.Return";

		["do"] = "Keyword";
		["then"] = "Keyword";
		["until"] = "Keyword";
		["end"] = "Keyword.Control";

		["function"] = "Keyword.Function";

		["local"] = "Keyword.Declare";

		["true"] = "Constant.Boolean";
		["false"] = "Constant.Boolean";
		["nil"] = "Constant.Null";
	};

	symbols = {
		["="] = "Symbol";

		["["] = "Symbol.Bracket.Square";
		["]"] = "Symbol.Bracket.Square";
		["("] = "Symbol.Bracket.Round";
		[")"] = "Symbol.Bracket.Round";
		["{"] = "Symbol.Bracket.Curly";
		["}"] = "Symbol.Bracket.Curly";

		["+"] = "Operator.Math.Add";
		["-"] = "Operator.Math.Sub";
		["*"] = "Operator.Math.Mul";
		["/"] = "Operator.Math.Div";
		["%"] = "Operator.Math.Mod";
		["^"] = "Operator.Math.Pow";

		["=="] = "Operator.Compare.Eq";
		["~="] = "Operator.Compare.Neq";
		[">="] = "Operator.Compare.Gte";
		["<="] = "Operator.Compare.Lte";
		[">"] = "Operator.Compare.Gt";
		["<"] = "Operator.Compare.Lt";

		["#"] = "Operator.Len";

		["."] = "Symbol.Index";
		[":"] = "Symbol.Index";

		[","] = "Symbol.Sep";
		[";"] = "Symbol.Sep";
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
