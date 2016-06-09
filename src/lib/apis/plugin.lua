
--[[
	WaveLite.*
		event
			void bind(string event, function callback)
			void unbind(string event, function callback)
			void invoke(string event, ...)
				potential bugs and stuff if invoking events with bad parameters?
				maybe make this fire a "<plugin name>:event" event instead?
		editor
			editor open(string type, options {dependent on type})
			bool close(editor)

		resource
			void register(string type, string name, data)

	system
		string platform()
		void copy(string text)
		string paste()
]]
