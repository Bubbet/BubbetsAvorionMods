package.path = package.path .. ";data/scripts/lib/?.lua"
local ConfigLoaderDisk = include("ConfigLoaderDisk")

-- namespace ConfigLoader
ConfigLoader = {}

ConfigLoader.resetConfig = ConfigLoaderDisk.resetConfig

function ConfigLoader:initialize()
	if onServer() then
		self.modconfig = ConfigLoaderDisk:getConfig(Server().folder.. "/moddata/ConfigLoader", getScriptPath())
	else
		self.modconfig = ConfigLoaderDisk:getConfig("moddata/ConfigLoader", getScriptPath())
	end
	return self.modconfig
end

function ConfigLoader.__index(self, ind)
	if not rawget(self, 'modconfig') then
		ConfigLoader.initialize(self)
	end
	return rawget(self, 'modconfig')[ind]
end

return setmetatable(ConfigLoader:initialize(), {__index = ConfigLoader.__index})
