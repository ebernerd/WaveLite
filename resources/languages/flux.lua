
return {
	keywords = {
		["if"] = "Keyword";
		["else"] = "Keyword";
		["while"] = "Keyword";
		["for"] = "Keyword";
		["foreach"] = "Keyword";
		["in"] = "Keyword";
		["repeat"] = "Keyword";
		["until"] = "Keyword";
		["switch"] = "Keyword";
		["case"] = "Keyword";
		["default"] = "Keyword";
		["try"] = "Keyword";
		["catch"] = "Keyword";
		["class"] = "Keyword";
		["extends"] = "Keyword";
		["implements"] = "Keyword";
		["interface"] = "Keyword";
		["enum"] = "Keyword";
		["namespace"] = "Keyword";
		["using"] = "Keyword";
		["import"] = "Keyword";
		["return"] = "Keyword";
		["break"] = "Keyword";
		["continue"] = "Keyword";
		["auto"] = "Keyword";
		["void"] = "Keyword";
		["public"] = "Keyword";
		["private"] = "Keyword";
		["static"] = "Keyword";
		["let"] = "Keyword";
		["const"] = "Keyword";
		["throw"] = "Keyword";
		["super"] = "Keyword";
		["operator"] = "Keyword";
		["function"] = "Keyword";
		["new"] = "Keyword";
		["typeof"] = "Keyword";
		["final"] = "Keyword";
		["abstract"] = "Keyword";
		["and"] = "Keyword";
		["or"] = "Keyword";
		["safe"] = "Keyword";
		["true"] = "Constant.Boolean";
		["false"] = "Constant.Boolean";
		["null"] = "Constant.Null";
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
		["**"] = "Operator.Math.Pow";

		["+="] = "Operator.Math.Add";
		["-="] = "Operator.Math.Sub";
		["*="] = "Operator.Math.Mul";
		["/="] = "Operator.Math.Div";
		["%="] = "Operator.Math.Mod";
		["**="] = "Operator.Math.Pow";

		["++"] = "Operator.Math.Add";
		["--"] = "Operator.Math.Sub";

		["=="] = "Operator.Compare.Eq";
		["!="] = "Operator.Compare.Neq";
		[">="] = "Operator.Compare.Gte";
		["<="] = "Operator.Compare.Lte";
		[">"] = "Operator.Compare.Gt";
		["<"] = "Operator.Compare.Lt";

		["&"] = "Operator.Bitwise.And";
		["|"] = "Operator.Bitwise.Or";
		["^"] = "Operator.Bitwise.Xor";
		["<<"] = "Operator.Bitwise.Lshift";
		[">>"] = "Operator.Bitwise.Rshift";

		["&="] = "Operator.Bitwise.And";
		["|="] = "Operator.Bitwise.Or";
		["^="] = "Operator.Bitwise.Xor";
		["<<="] = "Operator.Bitwise.Lshift";
		[">>="] = "Operator.Bitwise.Rshift";

		["&&"] = "Operator.And";
		["||"] = "Operator.Or";

		["&&="] = "Operator.And";
		["||="] = "Operator.Or";

		["!"] = "Operator.Not";
		["#"] = "Operator.Len";
		["~"] = "Operator.Bitwise.Not";

		[".."] = "Operator.Range";
		["->"] = "Operator.Cast";

		["@"] = "Symbol.Preprocessor";

		["..."] = "Symbol.Vararg";

		["::"] = "Symbol.Index";
		["."] = "Symbol.Index";
		[":"] = "Symbol.Index";

		[","] = "Symbol.Sep";
		[";"] = "Symbol.Sep";
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
