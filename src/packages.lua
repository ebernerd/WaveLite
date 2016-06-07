themes = { }

local defaulttheme = {

	ProjectPanel = {
		Background = { 255, 255, 255 },
		Foreground = { 40, 40, 40 },
		Border = { 255, 255, 255, 0 },
	},
	TabRibbon = {
		Background = { 255, 255, 255 },
		Foreground = { 40, 40, 40 },
		Border = { 255, 255, 255, 0 },
	},
	Tabs = {
		Background = { 220, 220, 220 },
		Foreground = { 255, 255, 255 },
		Border = { 255, 255, 255, 0 },
		Selected = { 33, 150, 243 },
	},
	Alerts = {
		Background = { 255, 255, 255 },
		Foreground = { 40, 40, 40 },
		Border = { 140, 140, 140 }
	},
	FileMenu = {
		Background = { 33, 150, 243 },
		Foreground = { 255, 255, 255 },
		Border = { 255, 255, 255, 0 },
	},
}

if not love.filesystem.isFile( "/user/packages/default.lua" ) then
	local t = { }
	t.Themes = { }
	t.Themes._Default = defaultTheme

	love.filesystem.newFile( "/user/packages/default.lua" )
	love.filesystem.write( "/user/packages/default.lua", t)
end

function packages.load()
	if not love.filesystem.isDirectory("/user/packages") then
		love.filesystem.createDirectory("/user/packages")
	end
	for _, v in pairs( love.filesystem.getDirectoryItems("/user/packages") ) do
		file, err = love.filesystem.newFileData( "/user/packages/" .. v )
		if file:getExtension() == "lua" or file:getExtension() == "wlpak" then

			local data = love.filesystem.load( "/user/packages/" .. v )()
			for i, PackageSection in pairs( data ) do
				if PackageSection == "Themes" then
					for name, theme in pairs( b ) do
						themes[ name ] = theme
					end
				elseif PackageSection == "Plugins" then
					--
				elseif PackageSection == "Styles" then
					--
				elseif PackageSection == "Languages" then
					--
				end
			end
		end
	end
end
return packages
