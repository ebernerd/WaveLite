
/*
Project structure:

	.project-info
	/plugins
		blah.lua
	/src
		main.lua

.project-info will contain stuff like...

	["editor:TabWidth"]
	["editor:StyleName"]
	["editor:TabLayout"]
	["UI:StyleName"]
*/

// so tabs need to be centralised in the WaveLite namespace...
// this _should_ work...

	<T {CodeEditor | TabManager}>
	void remove( T child ) {
		let div = child.parent;

		if div.type == "tabs" {
			div:removeEditor( child );
		}
		else {
			div:remove( child );
		}

		while (#div.children == 0 || #div.children == 1 && div.type == "tabs") && div != UIPanel.body {
			let parent = div.parent;
			parent:remove( div );
			div = parent;
		}
	}
